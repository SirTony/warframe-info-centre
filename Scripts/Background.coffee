app    = null
local  = null
sound  = null
config = null

newItemsCount = 0
isLoaded      = no

UPDATE_ALARM  = "UPDATE_ALARM"
SWEEPER_ALARM = "SWEEPER_ALARM"

shouldUpdate = ->
    return local.lastUpdate is null or now() - local.lastUpdate >= app.updateInterval

policeOldData = ->
    for k, v of local.alerts
        if not owns local.alerts, k
            continue
        
        if v.expireTime - now() <= -120
            delete local.alerts[k]

    Settings.update local

onLoadSettings = ( settings ) ->
    Log.Info "Firing load."
    if app?.platform? and settings.sync.platform isnt app.platform
        local = settings.local
        local.alerts    = { }
        local.invasions = { }
        newItemsCount   =  0
        Api.platform    = settings.sync.platform

        chrome.browserAction.setBadgeText text: ""
        Settings.update local
        update yes
    else
        local = settings.local

    app   = settings.sync
    sound = new Audio app.soundFile

    setup() unless isLoaded

onUpdateSettings = ( message ) ->
    Log.Info "Firing update."
    Settings.load()

onResetAlerts = ->
    chrome.browserAction.setBadgeText text: ""
    newItemsCount = 0

onShowNotification = ->
    unless App.Debug
        Log.Error "Only available in debug mode."
        return

    noty = new Notification "Test notification.", "Test notification message."
    noty.show 5

onPlaySound = ->
    unless App.Debug
        Log.Error "Only available in debug mode."
        return

    Log.Info "Has sound: #{if sound then 'yes' else 'no'}"
    sound.play() if sound

setup = ->
    policeOldData()
    sound = new Audio app.soundFile

    Message.on "UPDATE_SETTINGS",      onUpdateSettings
    Message.on "RESET_ALERTS_COUNTER", onResetAlerts
    Message.on "DEBUG_NOTIFY",         onShowNotification if App.Debug
    Message.on "DEBUG_SOUND",          onPlaySound        if App.Debug

    update() if shouldUpdate()

    mins = Math.max Math.floor 1, app.updateInterval / 60
    alarmOpts =
        periodInMinutes: mins
        delayInMinutes:  mins
    
    chrome.alarms.create UPDATE_ALARM, alarmOpts
    chrome.alarms.create SWEEPER_ALARM, alarmOpts

update = ( force = no ) ->
    notify =
        alerts:
            show:    null
            verbose: null
            quiet:   null
        invasions:
            show:    null
            verbose: null
            quiet:   null

    notify.alerts.show = ( ids ) =>
        return unless app.notify

        if app.noSpam
            notify.alerts.quiet ids
        else
            notify.alerts.verbose ids

    notify.alerts.verbose = ( ids ) =>
        for k, v of local.alerts
            continue if k not in ids

            message = "#{v.message}\n#{v.rewards.credits}"

            if v.rewards.extra.length > 0
                message += "\n#{v.rewards.extra.join ', '}"

            noty = new Notification "#{v.node} (#{v.planet}) - #{v.faction} #{v.type}", message
            noty.setType = "basic"
            noty.show 10

    notify.alerts.quiet = ( ids ) =>
        noty = new Notification "#{ids.length} new alerts"
        noty.setType = "list"
        count = 0

        for k, v of local.alerts
            continue if k not in ids
            ++count

            listItem =
                title: "#{v.node} (#{v.planet}) - #{v.faction} #{v.type}"
                message: "#{v.message}\n#{v.rewards.credits}"

            if v.rewards.extra.length > 0
                listItem.message += "\n#{v.rewards.extra.join ', '}"

            noty.addItem listItem

        return unless count > 0
        noty.show 10
    
    notify.invasions.show = ( ids ) =>
        return unless app.notify

        if app.noSpam
            notify.invasions.quiet ids
        else
            notify.invasions.verbose ids

    notify.invasions.verbose = ( ids ) =>
        for k, v of local.invasions
            continue if k not in ids

            message = "Rewards:\n\t#{v.factions.controlling.name} - #{v.factions.controlling.reward}"

            if v.factions.contestant.reward isnt null
                message += "\n\t#{v.factions.contestant.name} - #{v.factions.contestant.reward}"

            noty = new Notification "#{v.message} on #{v.node} (#{v.planet})", message
            noty.setType = "basic"
            noty.show 10

    notify.invasions.quiet = ( ids ) =>
        count = 0

        noty = new Notification "#{ids.length} new invasions"
        noty.setType "list"

        for k, v of local.invasions
            continue if k not in ids
            ++count

            listItem =
                title: "#{v.message} on #{v.length} (#{v.planet})"
                message: "Rewards:\n\t#{v.factions.controlling.name} - #{v.factions.controlling.reward}"

            if v.factions.contestant.reward isnt null
                listItem.message += "\n\t#{v.factions.contestant.name} - #{v.factions.contestant.reward}"

            noty.addItem listItem

        return unless count > 0
        noty.show 10

    handle = ( alerts, invasions ) =>
        newAlerts = keys( alerts ).filter ( x ) => x not of local.alerts
        newInvasions = keys( invasions ).filter ( x ) => x not of local.invasions

        newItemsCount += newAlerts.length
        newItemsCount += newInvasions.length if app.experimental

        return if newItemsCount is 0

        for k in newAlerts
            local.alerts[k] = alerts[k]

        notify.alerts.show newAlerts

        if newInvasions.length is 0 and not app.experimental
            sound.play()
            chrome.browserAction.setBadgeText text: newItemsCount.toString()
            Settings.update local
        
        return if app.experimental

        local.invasions = invasions
        notify.invasions.show newInvasions
        sound.play()
        chrome.browserAction.setBadgeText text: newItemsCount.toString()
        Settings.update local

    if force is yes or shouldUpdate()
        Log.Write "Updating."
        Api.getAlerts ( x ) =>
            Api.getInvasions ( y ) =>
                handle x, y

    ###
    finish = =>
        LocalSettings.update local, =>
            if newItemsCount > 0
                chrome.browserAction.setBadgeText text: newItemsCount.toString()
                if app.playSound
                    sound.play()

    if force is yes or shouldUpdate()
        Api.getAlerts ( dict ) =>
            local.lastUpdate = now()
                
            currentKeys = keys local.alerts
            newKeys = keys( dict ).filter ( x ) => x not in currentKeys
            newItemsCount += newKeys.length

            if app.notify
                if app.noSpam and newKeys.length > 1
                    if newKeys.length is 0
                        return

                    noty = new Notification "#{newKeys.length} new alerts"
                    noty.setType "list"

                    for k in newKeys
                        listObject =
                            title: "#{dict[k].node} (#{dict[k].planet}) - #{dict[k].faction} #{dict[k].type}"
                            message: "#{dict[k].message}\n#{dict[k].rewards.credits}"

                        if dict[k].rewards.extra.length > 0
                            other = dict[k].rewards.extra.join ", "
                            listObject.message += "\n#{other}"

                        noty.addItem listObject

                    noty.show 10 #10 second timeout
                else
                    if newKeys.length > 0
                        for k in newKeys
                            message = "#{dict[k].message}\n#{dict[k].rewards.credits}"

                            if dict[k].rewards.extra.length > 0
                                other = dict[k].rewards.extra.join ", "
                                message += "\n#{other}"

                            noty = new Notification "#{dict[k].node} (#{dict[k].planet}) - #{dict[k].faction} #{dict[k].type}", message
                            noty.setType "basic"
                            noty.show 10
                
            for k, v of dict
                if owns dict, k
                    local.alerts[k] = v
            
            finish() unless app.experimental
            #End Api.getAlerts

            if app.experimental
                Api.getInvasions ( dict ) =>
                    currentKeys = keys local.invasions
                    newKeys = keys( dict ).filter ( x ) => x not in currentKeys
                    newItemsCount += newKeys.length

                    if app.notify
                        if app.noSpam and newKeys.length > 1
                            if newKeys.length is 0
                                return

                            noty = new Notification "#{newKeys.length} new invasions"
                            noty.setType "list"

                            for k in newKeys
                                listObject =
                                    title: "#{dict[k].message} on #{dict[k].node} (#{dict[k].planet})"
                                    message: "Rewards:\n"

                                if dict[k].factions.contestant.reward is null
                                    listObject.message += "\t#{dict[k].factions.controlling.name} - #{dict[k].factions.controlling.reward}"
                                else
                                    listObject.message += "\t#{dict[k].factions.controlling.name} - #{dict[k].factions.controlling.reward}\n" +
                                                            "\t#{dict[k].factions.contestant.name} - #{dict[k].factions.contestant.reward}"

                                noty.addItem listObject
                            noty.show 10
                        else
                            if newKeys.length > 0
                                for k in newKeys
                                    message = "Rewards:\n"

                                    if dict[k].factions.contestant.reward is null
                                        message += "\t#{dict[k].factions.controlling.name} - #{dict[k].factions.controlling.reward}"
                                    else
                                        message += "\t#{dict[k].factions.controlling.name} - #{dict[k].factions.controlling.reward}\n" +
                                                    "\t#{dict[k].factions.contestant.name} - #{dict[k].factions.contestant.reward}"

                                    noty = new Notification "#{dict[k].message} on #{dict[k].node} (#{dict[k].planet})", message
                                    noty.setType "basic"
                                    noty.show 10

                    local.invasions = dict
                    finish()

                #End Api.getInvasions
    ###

###
    The reload param is for telling the function whether or not
    the extension has already been initialized.
    
    If reload is true, the extension has been loaded once
    and we don't want to call setup() again.
    
    If reload is false, this is the first time the settings
    are being loaded, and we need to run the setup() function.
###
loadConfig = ( reload ) ->
    Settings.on "load", onLoadSettings
    Settings.load()

    ###
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
    ###

__resetCheck =
    silent: no
    callCount: 1

clearData = ( quick = no ) ->
    unless App.Debug
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
    chrome.browserAction.setBadgeBackgroundColor color: "#5A8FE6"

    chrome.alarms.onAlarm.addListener ( alarm ) =>
        switch alarm.name
            when UPDATE_ALARM
                update() if shouldUpdate()
            when SWEEPER_ALARM
                policeOldData()

    loadConfig no