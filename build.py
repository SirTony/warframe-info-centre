import coffeescript as coffee
import os

for root, dirs, files in os.walk( os.sep.join( [ os.getcwd(), "Scripts" ] ) ):
    for file in files:
        _, extension = os.path.splitext( file )
        
        if extension != ".coffee":
            continue
        
        print "Compiling %s..." % file
        fullPath = os.sep.join( [ root, file ] )
        jsFile = os.sep.join( [ root, _ + ".js" ] )
        compiled = coffee.compile_file( fullPath, bare = True )

        with open( jsFile, "w" ) as js:
            js.write( compiled )
            js.flush()