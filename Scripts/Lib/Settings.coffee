StorageLocation =
    Sync:  2
    Local: 4
    Both:  6

Settings = new (
    class
        ASSOC_LOCAL = 0
        ASSOC_SYNC  = 1

        defaults =
            app:
                platform: "PC"
                updateInterval: 60
                experimental: no
                notify: yes
                noSpam: yes
                playSound: no
                soundFile: chrome.extension.getURL( "/Audio/It%20Is%20Time%20Tenno.mp3" )
                alerts:
                    showCreditOnly: yes
                    minimumCash: 5000
                    showBlueprint: no
                    showNightmare: no
                    showResource: no
                blueprints: [ ]
                mods: [ ]
                resources: [ ]

            local:
                alerts: { }
                invasions: { }
                lastUpdate: null

        handlers =
            update:     [ ]
            load:       [ ]
            load_sync:  [ ]
            load_local: [ ]

        associations =
            #Locals
            invasions:      ASSOC_LOCAL
            lastUpdate:     ASSOC_LOCAL

            #Sync storage
            platform:       ASSOC_SYNC
            updateInterval: ASSOC_SYNC
            experimental:   ASSOC_SYNC
            notify:         ASSOC_SYNC
            noSpam:         ASSOC_SYNC
            playSound:      ASSOC_SYNC
            soundFile:      ASSOC_SYNC
            blueprints:     ASSOC_SYNC
            mods:           ASSOC_SYNC
            resources:      ASSOC_SYNC

        constructor: ->
            return unless window is chrome.extension.getBackgroundPage()

            chrome.storage.sync.get null, ( x ) =>
                if chrome.runtime.lastError?
                    throw new StorageException chrome.runtime.lastError
                else
                    chrome.storage.local.get null, ( y ) =>
                        if chrome.runtime.lastError?
                            throw new StorageException chrome.runtime.lastError
                        else
                            for k, _ of defaults.app
                                continue unless owns defaults.app, k

                                if k not of x
                                    this.update defaults.app
                                    break

                            for k, _ of defaults.local
                                continue unless owns defaults.local, k
                                
                                if k not of y
                                    this.update defaults.local
                                    break

        on: ( event, fn ) ->
            if event not in keys handlers
                Log.Error( "Unknown event '#{event}' to Settings.on." )
                return

            handlers[event].push
                host: window
                callback: fn if isFunction fn

        load: ( where = StorageLocation.Both ) ->
            if where is StorageLocation.Sync
                chrome.storage.sync.get null, ( x ) =>
                    if chrome.runtime.lastError?
                        throw new StorageException chrome.runtime.lastError
                    else
                        dispatch "load_sync", x
            else if where is StorageLocation.Local
                chrome.storage.local.get null, ( x ) =>
                    if chrome.runtime.lastError?
                        throw new StorageException chrome.runtime.lastError
                    else
                        dispatch "load_local", x
            else if where is StorageLocation.Both
                chrome.storage.sync.get null, ( x ) =>
                    if chrome.runtime.lastError?
                        throw new StorageException chrome.runtime.lastError
                    else
                        chrome.storage.local.get null, ( y ) =>
                            if chrome.runtime.lastError?
                                throw new StorageException chrome.runtime.lastError
                            else
                                dispatch "load",
                                    sync:  x
                                    local: y

        update: ( values ) ->
            for k, v of values
                continue unless owns values, k
                continue unless k in keys( associations ) or k is "alerts"
                
                Log.Write "Handling #{k}."

                if k == "alerts"
                    #we need to handle alerts specially, since both sync and local
                    #have a key named alerts.
                    _keys = keys v

                    if keys( v ).equals [ "showCreditOnly", "minimumCash", "showBlueprint", "showNightmare", "showResource" ]
                        store = chrome.storage.sync
                        Log.Write "alerts element associated with SYNC"
                    else
                        store = chrome.storage.local
                        Log.Write "alerts element associated with LOCAL"
                else
                    assoc = associations[k]
                    store = switch
                                when assoc is ASSOC_LOCAL then chrome.storage.local
                                when assoc is ASSOC_SYNC  then chrome.storage.sync

                Log.Write "#{k} assocated with #{if assoc is ASSOC_SYNC then 'sync' else 'local'}"
                singleObject = { }
                singleObject[k] = v
                store.set singleObject, =>
                    dispatch "update"

        dispatch = ( event, params... ) ->
            functions = handlers[event]
            Log.Write functions

            for i in [0 ... functions.length]
                handle = functions[i]
                continue unless handle.host is window
                Log.Write "Calling #{event} no. #{i + 1}."
                handle.callback?( params... )
)