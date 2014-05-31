var coffee = require( "coffee-script" );
var less   = require( "less" );
var path   = require( "path" );
var fs     = require( "fs" );

var enc = { encoding: "utf8" };

function main( argv )
{
    argv = argv.map( function( x ) {
        return x.toLowerCase()
                .replace( /^-+/g, "" )
                .replace( /-+$/g, "" );
    } );
    
    var debugMode = argv.indexOf( "debug" )  !== -1;
    var traceMode = argv.indexOf( "trace" )  !== -1;
    var doExport  = argv.indexOf( "export" ) !== -1;
    
    console.log( "Generating App.js..." );
    
    //Generate App.js for the extension to set global properties.
    var setter = function( name, indentLevel ) {
        if( indentLevel == null )
            indentLevel = 1;
            
        var pad1 = " ".repeat( indentLevel * 4 );
        var pad2 = " ".repeat( indentLevel * 8 );
        
        return "set " + name + "( _ ) {\n" + pad2 + "throw \"Setting '" + name + "' is forbidden.\";\n" + pad1 + "}";
    };
    
    var getter = function( name, retval, indentLevel ) {
        if( indentLevel == null )
            indentLevel = 1;
    
        var pad1 = " ".repeat( indentLevel * 4 );
        var pad2 = " ".repeat( indentLevel * 8 );
        
        return "get " + name + "() {\n" + pad2 + "return " + retval.toString() + ";\n" + pad1 + "}";
    };
    
    var manifest = fs.readFileSync( "manifest.json", enc );
    var version  = manifest.match( /"version":\s*"(\d+).(\d+).(\d+).(\d+)"/ ).slice( 1, 5 ).map( function( x ) { return +x; } );
    
    var vid = version.slice( 0 ).map( function( x ) { return Math.max( 1, x ); } );
    vid[0] *= 100000;
    vid[1] *= 10000;
    vid[2] *= 100;
    vid = vid.reduce( function( a, b ) { return a + b; } );
    
    var varr = "[ " + version.join( ", " ) + " ]";
    var vobj = " {\n" +
               "            Major: " + version[0] + ",\n" +
               "            Minor: " + version[1] + ",\n" +
               "            Build: " + version[2] + ",\n" +
               "            Revision: " + version[3] + ",\n\n" +
               "            " + getter( "asArray", varr, 2 ).replace( "}", "    }" ) + ",\n\n" +
               "            " + setter( "asArray", 2 ).replace( "}", "    }" ) + "\n        }"
    
    var props = {
        "Debug": debugMode,
        "Trace": traceMode,
        "Version": vobj,
        "VersionID": vid.toString(),
        "VersionString": "\"" + version.join( "." ) + "\""
    };
    
    var app = "var App = {\n";
    
    for( var key in props )
    {
        app += "    " + getter( key, props[key] ) + ",\n\n" +
               "    " + setter( key ) + ",\n\n";
    }
    
    app = app.replace( /[\r\n\t\s,]*$/, "" );
    app += "\n};\n\nApp = Object.freeze( App );"
    
    fs.writeFileSync( "Scripts/App.js", app );
    compile();
}

String.prototype.repeat = function( num ) {
    return new Array( num + 1 ).join( this );
}

function walk( dir, fn )
{
    var files = [ ];
    
    fs.readdir( dir, function( e, list ) {
        if( e )
            return fn( e, null );
        
        var pending = list.length;
        
        if( !pending )
            return fn( null, files );
        
        list.forEach( function( file ) {
            file = path.join( dir, file );
            
            fs.stat( file, function( e, stat ) {
                if( stat && stat.isDirectory() )
                {
                    walk( file, function( e, res ) {
                        files = files.concat( res );
                        
                        if( !--pending )
                            fn( null, files );
                    } );
                }
                else
                {
                    files.push( file );
                    
                    if( !--pending )
                        fn( null, files );
                }
            } );
        } );
    } );
}

function compile()
{
    walk( process.cwd(), function( e, files )
    {
        if( e )
            return console.log( e );

        csFiles = files.filter( function( item ) {
            return path.extname( item ).toLowerCase() == ".coffee";
        } );

        lessFiles = files.filter( function( item ) {
            return path.extname( item ).toLowerCase() == ".less";
        } );

        for( var i = 0; i < csFiles.length; ++i )
        {
            var item = csFiles[i];
            var outfile = item.replace( /\.coffee$/i, ".js" );

            console.log( "Compiling " + path.basename( item ) + "..." );
            var raw = fs.readFileSync( item, enc  );
            var compiled = coffee.compile( raw, { bare: true } );
            fs.writeFileSync( outfile, compiled, enc );
        }

        while( lessFiles.length > 0 )
        {
            var item = lessFiles[0];
            var outfile = item.replace( /\.less$/i, ".css" );

            console.log( "Compiling " + path.basename( item ) + "..." );

            var raw = fs.readFileSync( item, enc );

            //async code is a pain in my ass
            less.render( raw, function( e, compiled ) {
                if( e )
                    return console.log( e );

                fs.writeFileSync( outfile, compiled, enc );
                lessFiles.shift();
            } );
        }
    } );
}

main( process.argv.slice( 2 ) );