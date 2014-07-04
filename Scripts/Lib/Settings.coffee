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

        @storage.get name, ( x ) =>
            if chrome.runtime.lastError?
                throw new StorageException chrome.runtime.lastError.message
            else
                callback? x
    
    ###
        getValues is a variadic function with the signature: void getValues( string ..., function callback );
    ###
    getValues: ( values..., fn ) ->
        for arg in values
            if not isString arg
                throw new ArgumentException "Expected first {0} parameters to be of type string, got {1}".format args.length - 1, args.map(  ( x ) -> typeof x ).join ", "
        
        @storage.get values, ( x ) =>
            if chrome.runtime.lastError?
                throw new StorageException chrome.runtime.lastError.message
            else
                fn? x
    
    getAll: ( callback ) ->
        if not isFunction callback
            throw new ArgumentException "Expected parameter 1 to be a function, got {0}.".format typeof callback
        
        @storage.get null, ( x ) =>
            if chrome.runtime.lastError?
                throw new StorageException chrome.runtime.lastError.message
            else
                callback? x
    
    update: ( data, callback ) ->
        if not isObject data
            throw new ArgumentException "Expected parameter 1 to be an object, got {0}.".format typeof data
        
        if not isFunction callback
            throw new ArgumentException "Expected parameter 2 to a function, got {0}.".format typeof callback
        
        @storage.set data, =>
            if chrome.runtime.lastError?
                throw new StorageException chrome.runtime.lastError.message
                
            callback?()

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