app   = null
local = null
sound = null
activeNotifications = [ ]
newItemsCount = 0

DEBUG = on

appDefaults = {
    platform: "PC",
    updateInterval: 60,
    notify: yes,
    #noSpam: yes,
    playSound: no,
    soundFile: chrome.extension.getURL( "/Audio/It%20Is%20Time%20Tenno.mp3" ),
    alerts: {
        showCreditOnly: yes,
        minimumCash: 5000,
        showBlueprint: no,
        showNightmare: no,
        showResource: no
    },
    blueprints: [ ],
    mods: [ ],
    resources: [ ]
}

localDefaults = {
    alerts: { },
    invasions: { },
    lastUpdate: null
}

shouldUpdate = ->
    console.trace "Checking update status."
    return local.lastUpdate is null or now() - local.lastUpdate >= app.updateInterval

policeOldData = ->
    for k, v of local.alerts
        if not local.alerts.owns k
            continue
        
        __now = now()
        
        if v.expireTime - __now <= -120
            delete local.alerts[k]
    
    for k, v of local.invasions
        if not local.invasions.owns k
            continue

        if Math.abs( v.score.current ) >= v.score.goal
            delete local.invasions[k]

    LocalSettings.update local, ->

setup = ->
    console.trace "Setting up extension."

    console.log app.soundFile
    sound = new Audio app.soundFile

    chrome.notifications.onClicked.addListener ( id ) ->
        if id in activeNotifications
            chrome.notifications.clear id, ->
                delete activeNotifications[activeNotifications.indexOf id]

    chrome.runtime.onMessage.addListener ( message, sender, reply ) ->
        if not DEBUG and not ( sender.id is "khlkgkdlljlbgpjflpjampkadjnldfec" )
            console.error "Unregocnized sender: {0}".format sender.id
            return

        switch message.action
            when "UPDATE_SETTINGS"
                AppSettings.getAll ( dict ) ->
                    console.log app

                    if not ( dict.platform is app.platform )
                        local.alerts = { }
                        newItemsCount = 0
                        
                    app = dict
                    sound = new Audio app.soundFile
                    
                    LocalSettings.update local, ->
                        reply { status: yes }
                        Api.platform = app.platform
                        update yes
                        return
                    return
            when "RESET_ALERTS_COUNTER"
                newItemsCount = 0
                reply { status: yes }
            else
                reply { action: message.action, status: no, message: "Unrecognised action '{0}'.".format message.action }
        return

    if shouldUpdate()
        update()
    
    setInterval update, ( app.updateInterval * 1000 ) - 500
    setInterval policeOldData, 30000 #Remove every 30 seconds.
    return

update = ( force = no )->
    console.trace "Running updater."
    
    if force is yes or shouldUpdate()
        console.trace "Updating."

        notifyOpts = {
            type: "basic",
            iconUrl: chrome.extension.getURL "/Icons/Warframe.Large.png"
        }
        
        Api.getAlerts ( dict ) ->
            console.log( "Fetched data." );
            console.log( dict );
            
            local.lastUpdate = now()
                
            currentKeys = local.alerts.keys()
            newKeys = dict.keys().filter ( x ) -> not ( x in currentKeys )
            newItemsCount += newKeys.length

            if newKeys.length > 0
                for k in newKeys
                    notifyOpts.title = "#{dict[k].node} (#{dict[k].planet}) - #{dict[k].faction} #{dict[k].type}"
                    notifyOpts.message = "#{dict[k].message}\n#{dict[k].rewards.credits}"

                    if dict[k].rewards.extra.length > 0
                        other = dict[k].rewards.extra.join ", "
                        notifyOpts.message += "\n#{other}"

                    chrome.notifications.create k, notifyOpts, ( s ) ->
                        activeNotifications.push s
                        setTimeout ( ->
                            if s in activeNotifications
                                chrome.notifications.clear s, ->
                                    delete activeNotifications[activeNotifications.indexOf s]
                        ), 10000
                
            for k, v of dict
                if dict.owns k
                    local.alerts[k] = v
             
            #End Api.getAlerts

            Api.getInvasions ( dict ) ->
                currentKeys = local.invasions.keys()
                newKeys = dict.keys().filter ( x ) -> not ( x in currentKeys )
                newItemsCount += newKeys.length

                if newKeys.length > 0
                    for k in newKeys
                        notifyOpts.title = "#{dict[k].message} on #{dict[k].node} (#{dict[k].planet})"
                        notifyOpts.message = "Rewards:\n"

                        if dict[k].factions.contestant.reward is null
                            notifyOpts.message += "\t#{dict[k].factions.controlling.name}: #{dict[k].factions.controlling.reward}"
                        else
                            notifyOpts.message += "\t#{dict[k].factions.controlling.name}: #{dict[k].factions.controlling.reward}\n" +
                                                  "\t#{dict[k].factions.contestant.name}: #{dict[k].factions.contestant.reward}"

                        chrome.notifications.create k, notifyOpts, ( s ) ->
                            activeNotifications.push s
                            setTimeout ( ->
                                if s in activeNotifications
                                    chrome.notifications.clear s, ->
                                        delete activeNotifications[activeNotifications.indexOf s]
                            ), 10000

                for k, v of dict
                    if dict.owns k
                        local.invasions[k] = v

                LocalSettings.update local, ->
                    console.log "Updated local settings."

                    if newItemsCount > 0
                        chrome.browserAction.setBadgeText { text: newItemsCount.toString() }

                    if app.playSound
                        sound.play()

                #End Api.getInvasions
    else
        console.trace "No need to update."

###
    The reload param is for telling the function whether or not
    the extension has already been initialized.
    
    If reload is true, the extension has been loaded once
    and we don't want to call setup() again.
    
    If reload is false, this is the first time the settings
    are being loaded, and we need to run the setup() function.
###
loadConfig = ( reload ) ->
    console.trace "Loading configuration (reload: {0}).".format( if reload is yes then "yes" else "no" )
    
    ###
        For anyone wondering about all the silly empty return
        statements in this function, refer to ./Lib/Settings.coffee
        on lines 15 to 21 for the reason they're needed.
    ###
    
    AppSettings.getAll ( appRes ) ->
        if isUndefined( appRes ) or appRes is null or not ( appRes.keys().length is appDefaults.keys().length )
            AppSettings.update appDefaults, ->
                AppSettings.getAll ( appRes2 ) ->
                    app = appRes2
                    return
                return
        else
            app = appRes
        
        LocalSettings.getAll ( locRes ) ->
            if isUndefined( locRes ) or locRes is null or not ( locRes.keys().length is localDefaults.keys().length )
                LocalSettings.update localDefaults, ->
                    LocalSettings.getAll ( locRes2 ) ->
                        local = locRes2
                    
                        if reload is no
                            setup()
                            return
                    return
            else
                local = locRes
                
                if reload is no
                    setup()
            
            return
        return
    return

__resetCheck = {
    silent: no,
    callCount: 1
}

clearData = ( quick = no ) ->
    if quick is yes and __resetCheck.silent is no
        __resetCheck.silent = yes;
    
    if __resetCheck.silent is yes or __resetCheck.callCount % 2 is 0
        chrome.storage.local.clear()
        chrome.storage.sync.clear()
        console.log "Cleared."
    else
        console.warn "WARNING: clearData() is convenience function to aid in testing and debugging. " + \
                     "It will wipe all userdata associated with Warframe Info Centre. " + \
                     "If you would like to proceed, please call this function again, " + \
                     "or call with clearData( true ); to silence this message."
    
    __resetCheck.callCount++
    return

try
    loadConfig no
catch e
    type = Exception.getType e
    if type is null
        console.error e.stack.toString()
    else
        console.error "{0}: {1}".format type, e.getMessage()
