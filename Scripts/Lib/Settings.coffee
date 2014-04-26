class SettingsBase

	allowedTypes = [
		chrome.storage.sync,
		chrome.storage.local,
		chrome.storage.managed 
	]
	
	#these two lines need semicolons or Notepad++'s
	#syntax highlighter has a stroke and dies.
	#the CoffeeScript compiler doesn't give a flying fuck
	#whether we use semicolons or not.
	storage  = null;
	defaults = null;
	
	constructor: ( store, defaultValues = null ) ->
		if not ( store in allowedTypes )
			throw new ArgumentException "Invalid storage location."

		#using parentheses for the same reason as the semicolons.
		#fuck Notepad++'s bullshit.
		if( defaultValues == null )
			throw new ArgumentException "Default values are required."
		
		storage  = store
		defaults = defaultValues
		
		@verify ( valid ) ->
			if not valid
				@install()

	#Get a single value by name.
	getValue: ( name, callback ) ->
		if not isString name
			throw new AppException ""

		if not isFunction callback
			throw new AppException ""

		storage.get name, ( x ) ->
			if not isUndefined chrome.runtime.lastError
				throw new StorageException chrome.runtime.lastError.message
			else
				callback x
	
	getValues: ->
		if arguments.length < 2
			throw new ArgumentException "Expected at least two arguments, got {0}".format arguments.length
		
		args = arguments.values()
		
		for arg in args.slice 0, -1
			if not isString arg
				throw new ArgumentException "Expected first {0} parameters to be of type string, got {1}".format args.length - 1, args.map(  ( x ) -> typeof x ).join ", "
		
		names = args.slice 0, -1
		callback = args.slice( -1 ).pop()
		
		if not isFunction callback
			throw new ArgumentException "Expected last parameter to be a function, got {0}".format typeof callback
		
		storage.get names, ( x ) ->
			if not isUndefined chrome.runtime.lastError
				throw new StorageException chrome.runtime.lastError.message
			else
				callback x
	
	getAll: ( callback ) ->
		if not isFunction callback
			throw new ArgumentException "Expected parameter 1 to be a function, got {0}.".format typeof callback
		
		storage.get null, ( x ) ->
			if not isUndefined chrome.runtime.lastError
				throw new StorageException chrome.runtime.lastError
			else
				callback x
	
	update: ( data ) ->
		if not isObject data
			throw new ArgumentException "Expected parameter 1 to be an object, got {0}.".format typeof callback
		
		storage.set data, ( x ) ->
			if not isUndefined chrome.runtime.lastError
				throw new StorageException chrome.runtime.lastError.message
	
	verify: ( callback ) ->
		if not isFunction callback
			throw new ArgumentException "Expected parameter 1 to be a function, got {0}.".format typeof callback
			
		@getAll ( x ) ->
			if not ( Object.keys( x ).length is Object.keys( defaults ).length )
				callback false; #*sigh* again
			else
				callback true; #yep
		
	install: ->
		@update defaults

AppSettings = new (
	class extends SettingsBase
		
		defaultSettings = {
			firstRun: false,
			platform: "PC",
			updateInterval: 60,
			notify: true,
			alerts: {
				showCreditOnly: true,
				minimumCash: 5000,
				showBlueprint: false,
				showNightmare: false,
				showResource:  ( false ) #Seriously, this is getting old
			},
			blueprints: [ ],
			mods: [ ],
			resources: [ ]
		}
	
		constructor: ->
			super chrome.storage.sync, defaultSettings				
)

LocalSettings = new (
	class extends SettingsBase
	
		defaultSettings = {
			alerts: [ ],
			lastUpdate: ( null ) #it really is
		}
		
		constructor: ->
			super chrome.storage.local, defaultSettings
)