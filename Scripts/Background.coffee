app   = null
local = null
sound = null
activeNotifications = [ ]
newItemsCount = 0

`const UPDATE_ALARM = "UPDATE_ALARM"`
`const SWEEPER_ALARM = "SWEEPER_ALARM"`

appDefaults = {
    platform: "PC",
    updateInterval: 60,
    notify: yes,
    noSpam: yes,
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
    return local.lastUpdate is null or now() - local.lastUpdate >= app.updateInterval

policeOldData = ->
    count = 0

    for k, v of local.alerts
        if not owns local.alerts, k
            continue
        
        __now = now()
        
        if v.expireTime - __now <= -120
            delete local.alerts[k]
            ++count
    ###
    for k, v of local.invasions
        if not local.invasions.owns k
            continue

        if Math.abs( v.score.current ) >= v.score.goal
            delete local.invasions[k]
    ###
    LocalSettings.update local, =>
        Log.Info "Removed #{count} old alerts."

setup = ->
    sound = new Audio app.soundFile

    chrome.notifications.onClicked.addListener ( id ) =>
        if id in activeNotifications
            chrome.notifications.clear id, =>
                delete activeNotifications[activeNotifications.indexOf id]

    chrome.runtime.onMessage.addListener ( message, sender, reply ) =>
        if not App.Debug and sender.id isnt chrome.runtime.id
            Log.Error "Unregocnized sender: {0}".format sender.id

        switch message.action
            when "UPDATE_SETTINGS"
                AppSettings.getAll ( dict ) =>

                    if not ( dict.platform is app.platform )
                        local.alerts = { }
                        newItemsCount = 0
                        
                    app = dict
                    sound = new Audio app.soundFile
                    
                    LocalSettings.update local, =>
                        reply { status: yes }
                        Api.platform = app.platform
                        update yes
            when "RESET_ALERTS_COUNTER"
                newItemsCount = 0
                reply status: yes
            else
                reply
                    action: message.action
                    status: no
                    message: "Unrecognised action '{0}'.".format message.action

    if shouldUpdate()
        update()

    mins = Math.max Math.floor 1, app.updateInterval / 60
    alarmOpts =
        periodInMinutes: mins
        delayInMinutes:  mins
    
    chrome.alarms.create UPDATE_ALARM, alarmOpts
    chrome.alarms.create SWEEPER_ALARM, alarmOpts

    #setInterval update, ( app.updateInterval * 1000 ) - 500
    #setInterval policeOldData, 30000 #Remove every 30 seconds.
    return

update = ( force = no )->
    if force is yes or shouldUpdate()
        notifyOpts =
            iconUrl: chrome.extension.getURL "/Icons/Warframe.Large.png"
        
        Api.getAlerts ( dict ) =>
            local.lastUpdate = now()
                
            currentKeys = keys local.alerts
            newKeys = keys( dict ).filter ( x ) => x not in currentKeys
            newItemsCount += newKeys.length

            if app.notify
                if app.noSpam or newKeys.length > 1
                    if newKeys.length is 0
                        return

                    notifyOpts.type  = "list"
                    notifyOpts.title = "#{newKeys.length} new alerts"
                    notifyOpts.items = [ ]
                    key = ""

                    for k in newKeys
                        key = k

                        listObject =
                            title: "#{dict[k].node} (#{dict[k].planet}) - #{dict[k].faction} #{dict[k].type}"
                            message: "#{dict[k].message}\n#{dict[k].rewards.credits}"

                        if dict[k].rewards.extra.length > 0
                            other = dict[k].rewards.extra.join ", "
                            listObject.message += "\n#{other}"

                        notifyOpts.items.push listObject
                    Log.Write notifyOpts
                    chrome.notifications.create key, notifyOpts, ( s ) =>
                        Log.Info "Created."
                        activeNotifications.push s
                        setTimeout ( =>
                            if s in activeNotifications
                                chrome.notifications.clear s, =>
                                    delete activeNotifications[activeNotifications.indexOf s]
                        ), 10000
                else
                    if newKeys.length > 0
                        notifyOpts.type = "basic"
                        delete notifyOpts.items

                        for k in newKeys
                            notifyOpts.title = "#{dict[k].node} (#{dict[k].planet}) - #{dict[k].faction} #{dict[k].type}"
                            notifyOpts.message = "#{dict[k].message}\n#{dict[k].rewards.credits}"

                            if dict[k].rewards.extra.length > 0
                                other = dict[k].rewards.extra.join ", "
                                notifyOpts.message += "\n#{other}"

                            chrome.notifications.create k, notifyOpts, ( s ) =>
                                activeNotifications.push s
                                setTimeout ( =>
                                    if s in activeNotifications
                                        chrome.notifications.clear s, =>
                                            delete activeNotifications[activeNotifications.indexOf s]
                                ), 10000
                
            for k, v of dict
                if owns dict, k
                    local.alerts[k] = v
             
            #End Api.getAlerts

            Api.getInvasions ( dict ) =>
                currentKeys = keys local.invasions
                newKeys = keys( dict ).filter ( x ) => x not in currentKeys
                newItemsCount += newKeys.length

                if app.notify
                    if app.noSpam or newKeys.length > 1
                        if newKeys.length is 0
                            return

                        notifyOpts.type  = "list"
                        notifyOpts.title = "#{newKeys.length} new invasions"
                        notifyOpts.items = [ ]
                        key = ""

                        for k in newKeys
                            key = k

                            listObject =
                                title: "#{dict[k].message} on #{dict[k].node} (#{dict[k].planet})"
                                message: "Rewards:\n"

                            if dict[k].factions.contestant.reward is null
                                listObject.message += "\t#{dict[k].factions.controlling.name} - #{dict[k].factions.controlling.reward}"
                            else
                                listObject.message += "\t#{dict[k].factions.controlling.name} - #{dict[k].factions.controlling.reward}\n" +
                                                      "\t#{dict[k].factions.contestant.name} - #{dict[k].factions.contestant.reward}"

                            notifyOpts.items.push listObject
                        Log.Write notifyOpts
                        chrome.notifications.create key, notifyOpts, ( s ) =>
                            Log.Write "Created."
                            activeNotifications.push s
                            setTimeout ( =>
                                if s in activeNotifications
                                    chrome.notifications.clear s, =>
                                        delete activeNotifications[activeNotifications.indexOf s]
                            ), 10000
                    else
                        if newKeys.length > 0
                            notifyOpts.type = "basic"
                            delete notifyOpts.items

                            for k in newKeys
                                notifyOpts.title = "#{dict[k].message} on #{dict[k].node} (#{dict[k].planet})"
                                notifyOpts.message = "Rewards:\n"

                                if dict[k].factions.contestant.reward is null
                                    notifyOpts.message += "\t#{dict[k].factions.controlling.name} - #{dict[k].factions.controlling.reward}"
                                else
                                    notifyOpts.message += "\t#{dict[k].factions.controlling.name} - #{dict[k].factions.controlling.reward}\n" +
                                                          "\t#{dict[k].factions.contestant.name} - #{dict[k].factions.contestant.reward}"

                                chrome.notifications.create k, notifyOpts, ( s ) =>
                                    activeNotifications.push s
                                    setTimeout ( =>
                                        if s in activeNotifications
                                            chrome.notifications.clear s, =>
                                                delete activeNotifications[activeNotifications.indexOf s]
                                    ), 10000

                local.invasions = dict
                ###
                for k, v of dict
                    if dict.owns k
                        local.invasions[k] = v
                ###
                LocalSettings.update local, =>
                    if newItemsCount > 0
                        chrome.browserAction.setBadgeText text: newItemsCount.toString()

                    if app.playSound
                        sound.play()

                #End Api.getInvasions

###
    The reload param is for telling the function whether or not
    the extension has already been initialized.
    
    If reload is true, the extension has been loaded once
    and we don't want to call setup() again.
    
    If reload is false, this is the first time the settings
    are being loaded, and we need to run the setup() function.
###
loadConfig = ( reload ) ->
    #TODO: unravel this horrid mess with promises.
    AppSettings.getAll ( appRes ) =>
        if not appRes? or not ( keys( appRes ).length is keys( appDefaults ).length )
            AppSettings.update appDefaults, =>
                AppSettings.getAll ( appRes2 ) =>
                    app = appRes2
        else
            app = appRes
        
        LocalSettings.getAll ( locRes ) =>
            if not locRes? or not ( keys( locRes ).length is keys( localDefaults ).length )
                LocalSettings.update localDefaults, =>
                    LocalSettings.getAll ( locRes2 ) =>
                        local = locRes2
                    
                        if reload is no
                            setup()
            else
                local = locRes
                
                if reload is no
                    setup()

__resetCheck =
    silent: no
    callCount: 1

clearData = ( quick = no ) ->
    if not App.Debug
        return

    if quick is yes and __resetCheck.silent is no
        __resetCheck.silent = yes
    
    if __resetCheck.silent is yes or __resetCheck.callCount % 2 is 0
        chrome.storage.local.clear()
        chrome.storage.sync.clear()
        Log.Write "Cleared."
    else
        Log.Warn    "WARNING: clearData() is convenience function to aid in testing and debugging. " + \
                     "It will wipe all userdata associated with Warframe Info Centre. " + \
                     "If you would like to proceed, please call this function again, " + \
                     "or call with clearData( true ); to silence this message."
    
    __resetCheck.callCount++
    return

except ->
    chrome.alarms.onAlarm.addListener ( alarm ) =>
        switch alarm.name
            when UPDATE_ALARM
                update yes
            when SWEEPER_ALARM
                policeOldData()

    loadConfig no