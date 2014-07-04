coffee = require "coffee-script"
less   = require "less"
path   = require "path"
fs     = require "fs"

#Set up command-line options.
option "-d", "--debug", "Add debug information."
option "-t", "--trace", "Add trace information."

#The real meat and potatoes, the tasks.
task "build:scripts", "Build only CoffeeScript files.", ( options ) =>
    console.log "Building JavaScript files..."
    coffeeFiles = options.files.filter ( x ) => path.extname( x ).toLowerCase() is ".coffee"
    
    buildAppFile options
    
    for i in [ 0 ... coffeeFiles.length ] by 1
        file = coffeeFiles[i]
        newFile = file.replace /\.coffee$/i, ".js"
        
        console.log "  - Building #{path.basename newFile}..."
        
        raw = fs.readFileSync file, encoding: "utf8"
        compiled = coffee.compile raw, { bare: true }
        fs.writeFileSync newFile, compiled, encoding: "utf8"

task "build:styles", "Build only LESS files.", ( options ) =>
    console.log "Building LESS files..."
    lessFiles = options.files.filter ( x ) => path.extname( x ).toLowerCase() is ".less"
    
    while lessFiles.length > 0
        file = lessFiles[0]
        newFile = file.replace /\.less$/i, ".css"
        
        console.log "  - Building #{path.basename newFile}..."
        
        raw = fs.readFileSync file, encoding: "utf8"
        
        less.render raw, ( e, compiled ) =>
            return console.log e if e
            
            fs.writeFileSync newFile, compiled, encoding: "utf8"
            lessFiles.shift()

task "build", "Build source files.", ( options ) =>
    options.files = fs.walk()
    invoke "build:scripts", options
    invoke "build:styles", options

task "export", "Export compiled files for packaging.", ( options ) =>
    console.log "Exporting files..."
    
    files = fs.walk().filter ( x ) => path.extname( x ).toLowerCase() in [ ".js", ".css", ".html", ".mp3", ".png", ".ttf", ".json" ]
    here  = path.resolve __dirname
    bin   = path.join here, "Bin"
    
    if fs.existsSync bin
        fs.deleteDirectory bin
    
    fs.mkdirSync bin
    
    for i in [ 0 ... files.length ] by 1
        source = files[i]
        name   = source.replace process.cwd(), ""
        dest   = path.join bin, name
        
        console.log "  - Exporting #{path.basename dest}."
        
        if not fs.existsSync path.dirname dest
            fs.mkdirRecursive path.dirname dest
        
        fs.copyFile source, dest
    
    console.log "Finished exporting files."

task "clean", "Cleans all compiled and exported files.", ( options ) =>
    console.log "Cleaning build files..."
    
    bin = path.join path.resolve( __dirname ), "Bin"
    
    fs.deleteDirectory bin if fs.existsSync bin
    rest = fs.walk().filter ( x ) => path.extname( x ).toLowerCase() in [ ".js", ".css" ]
    
    for i in [ 0 ... rest.length ] by 1
        file = rest[i]
        jquery = path.basename( file ).match( /jquery/i )?
        
        console.log "  - Removing #{path.basename file}." unless jquery
        fs.unlinkSync file unless jquery

#All functions are sync, because async code is a pain in the ass here.
buildAppFile = ( options ) ->
    console.log "  - Building App.js..."
    
    setter = ( name, indent = 1 ) ->
        padOnce  = " ".repeat indent * 4
        padTwice = " ".repeat indent * 8
        
        return "set #{name}() {\n#{padTwice}throw \"Setting '#{name}' is forbidden.\";\n#{padOnce}}"
    
    getter = ( name, retval, indent = 1 ) ->
        padOnce  = " ".repeat indent * 4
        padTwice = " ".repeat indent * 8
        
        return "get #{name}() {\n#{padTwice}return #{retval};\n#{padOnce}}"
    
    manifest       = fs.readFileSync "manifest.json", encoding: "utf8"
    version       = manifest.match( /"version":\s*"(\d+).(\d+).(\d+).(\d+)"/ )[1 ... 5].map ( x ) => +x
    versionId     = version[..].map ( x ) => Math.max 1, x
    versionId[0] *= 100000
    versionId[1] *= 10000
    versionId[2] *= 100
    versionId     = versionId.reduce ( x, y ) => x + y
    versionArray  = "[ #{version.join ', '} ]"
    versionObject = "Object.freeze( {\n            Major: #{version[0]},\n            Minor: #{version[1]},\n            Build: #{version[2]},\n            Revision: #{version[3]},\n\n            #{getter( 'arArray', versionArray, 2 ).replace '}', '    }'},\n\n            #{setter( 'asArray', 2 ).replace '}', '    }'}\n        } )"

    properties =
        Debug: options.debug ? no,
        Trace: options.trace ? no,
        Version: versionObject,
        VersionID: versionId,
        VersionString: "\"#{version.join '.'}\""
    
    app = "const App = Object.freeze( {\n"
    
    for k, v of properties
        continue if not properties.hasOwnProperty k
        app += "    #{getter k, v},\n\n    #{setter k},\n\n"

    app  = app.replace /[\r\n\t\s,]*$/, ""
    app += "\n} );"
    
    fs.writeFileSync path.join( "Scripts", "App.js" ), app, encoding: "utf8"

String::repeat = ( count ) -> new Array( count + 1 ).join @

fs.copyFile = ( source, target ) ->
    BUFFER_SIZE = 65536
    
    buffer = new Buffer BUFFER_SIZE
    
    reader = fs.openSync source, "r"
    writer = fs.openSync target, "w"
    
    amountRead = 1
    position   = 0
    
    while amountRead > 0
        amountRead = fs.readSync reader, buffer, 0, BUFFER_SIZE, position
        fs.writeSync writer, buffer, 0, amountRead
        position += amountRead
    
    fs.closeSync reader
    fs.closeSync writer
    
fs.deleteDirectory = ( source ) ->
    if fs.existsSync source
        here = fs.readdirSync source
        here.forEach ( file ) =>
            file = path.join source, file
            stat = fs.statSync file
            
            return if not stat
            
            if stat.isDirectory()
                fs.deleteDirectory file
            else
                fs.unlinkSync file
        
        fs.rmdirSync source

fs.mkdirRecursive = ( directoryPath, mode ) ->
    try
        fs.mkdirSync directoryPath, mode
    catch
        fs.mkdirRecursive path.dirname( directoryPath ), mode
        fs.mkdirRecursive directoryPath, mode

fs.walk = ( source = process.cwd() ) ->
    files = [ ]
    
    if fs.existsSync source
        here = fs.readdirSync source
        here.forEach ( file ) =>
            file = path.join source, file
            stat = fs.statSync file
            
            return if not stat
            
            if stat.isDirectory()
                files.push fs.walk( file )...
            else
                files.push file
    
    files