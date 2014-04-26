class Settings

	allowedTypes = [
		chrome.storage.sync,
		chrome.storage.local,
		chrome.storage.managed 
	]
	
	constructor: ( store ) ->
		if not ( store in allowedTypes )
			throw new ArgumentException "Invalid storage location."
		
		@storage = store
	
	###
		NOTE: for functions getValue(), getValues(), and getAll(),
		explicit empty return statements are needed to prevent Coffee
		from implicitly returning the last expression in scope when
		compiling to JS. Not doing so will dick with all the callback
		voodoo.
	###

	#Get a single value by name.
	getValue: ( name, callback ) ->
		if not isString name
			throw new AppException ""

		if not isFunction callback
			throw new AppException ""

		@storage.get name, ( x ) ->
			if not isUndefined chrome.runtime.lastError
				throw new StorageException chrome.runtime.lastError.message
			else
				callback x
				return
		
		return
	
	###
		getValues is a variadic function with the signature: void getValues( string ..., function callback );
	###
	getValues: ->
		if arguments.length < 2
			throw new ArgumentException "Expected at least two arguments, got {0}".format arguments.length
		
		args = arguments.values no;
		
		for arg in args.slice 0, -1
			if not isString arg
				throw new ArgumentException "Expected first {0} parameters to be of type string, got {1}".format args.length - 1, args.map(  ( x ) -> typeof x ).join ", "
		
		names = args.slice 0, -1
		callback = args.slice( -1 ).pop()
		
		if not isFunction callback
			throw new ArgumentException "Expected last parameter to be a function, got {0}".format typeof callback
		
		@storage.get names, ( x ) ->
			if not isUndefined chrome.runtime.lastError
				throw new StorageException chrome.runtime.lastError.message
			else
				callback x
				return
		
		return
	
	getAll: ( callback ) ->
		if not isFunction callback
			throw new ArgumentException "Expected parameter 1 to be a function, got {0}.".format typeof callback
		
		@storage.get null, ( x ) ->
			if not isUndefined chrome.runtime.lastError
				throw new StorageException chrome.runtime.lastError.message
			else
				callback x
				return
		
		return
	
	update: ( data, callback ) ->
		if not isObject data
			throw new ArgumentException "Expected parameter 1 to be an object, got {0}.".format typeof data
		
		if not isFunction callback
			throw new ArgumentException "Expected parameter 2 to a function, got {0}.".format typeof callback
		
		@storage.set data, ->
			if not isUndefined chrome.runtime.lastError
				throw new StorageException chrome.runtime.lastError.message
				
			callback()
			return
		
		return

###
AppSettings = new (
	class extends SettingsBase
		constructor: ->
			super chrome.storage.sync			
)

LocalSettings = new (
	class extends SettingsBase
		constructor: ->
			super chrome.storage.local
)
###

AppSettings   = new Settings chrome.storage.sync
LocalSettings = new Settings chrome.storage.local