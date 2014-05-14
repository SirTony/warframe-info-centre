var coffee = require( "coffee-script" );
var less   = require( "less" );
var path   = require( "path" );
var fs     = require( "fs" );

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

Array.prototype.filter = function( fn )
{
    var filtered = [ ];
    
    for( var i = 0; i < this.length; ++i )
        if( fn( this[i] ) )
            filtered.push( this[i] );
    
    return filtered;
};

walk( process.cwd(), function( e, files ) {
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
        var raw      = fs.readFileSync( item, { encoding: "utf8" } );
        var compiled = coffee.compile( raw, { bare: true } );
        fs.writeFileSync( outfile, compiled, { encoding: "utf8" } );
    }
    
    while( lessFiles.length > 0 )
    {
        var item = lessFiles[0];
        var outfile = item.replace( /\.less$/i, ".css" );
        
        console.log( "Compiling " + path.basename( item ) + "..." );
        
        var raw = fs.readFileSync( item, { encoding: "utf8" } );
        
        //async code is a pain in my ass
        less.render( raw, function( e, compiled ) {
            if( e )
                return console.log( e );
            
            fs.writeFileSync( outfile, compiled, { encoding: "utf8" } );
            lessFiles.shift();
        } );
    }
} );