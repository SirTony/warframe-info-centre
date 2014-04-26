import coffeescript as coffee
import os, execjs

for root, dirs, files in os.walk( os.sep.join( [ os.getcwd(), "Scripts" ] ) ):
    for file in files:
        _, extension = os.path.splitext( file )
        
        if extension != ".coffee":
            continue
        
        print "Compiling %s..." % file
        fullPath = os.sep.join( [ root, file ] )
        jsFile = os.sep.join( [ root, _ + ".js" ] )
        
        compiled = None
        
        try:
            compiled = coffee.compile_file( fullPath, bare = True )
        except execjs.ProgramError as e:
            print
            print e.message.replace( "[stdin]", file )
        else:    
            with open( jsFile, "w" ) as js:
                js.write( compiled )
                js.flush()