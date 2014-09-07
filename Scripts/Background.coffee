app   = null
local = null
sound = null
newItemsCount = 0

UPDATE_ALARM  = "UPDATE_ALARM"
SWEEPER_ALARM = "SWEEPER_ALARM"

appDefaults = {
    platform: "PC",
    updateInterval: 60,
    experimental: no,
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

    Settings.update { local: local }, =>
        Log.Info "Removed #{count} old alerts."

onUpdateSettings = ->
    Settings.fetch ( dict ) =>
        if dict.platform isnt app.platform
            local.alerts = { }
            local.invasions = { }

            Settings.update { local: local }, => update yes

        app = dict.sync
        sound = new Audio app.soundFile unless Audio?

onResetAlerts = ->
    Log.Write "Resetting."
    newItemsCount = 0

onShowNotification = ->
    unless App.Debug
        Log.Error "Only available in debug mode."
        return

    noty = new Notification "Test notification.", "Test notification message."
    noty.show 5

setup = ->
    policeOldData()
    sound = new Audio app.soundFile unless Audio?

    Message.on "UPDATE_SETTINGS",      onUpdateSettings
    Message.on "RESET_ALERTS_COUNTER", onResetAlerts
    Message.on "DEBUG_NOTIFY",         onShowNotification if App.Debug

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
        noty = new Notification "#{ids.length} new #{if ids.length > 1 then 'alerts' else 'alert'}"
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

        noty = new Notification "#{ids.length} new #{if ids.length > 1 then 'invasions' else 'invasion'}"
        noty.setType "list"

        for k, v of local.invasions
            continue if k not in ids
            ++count

            listItem =
                title: "#{v.message} on #{v.node} (#{v.planet})"
                message: "Rewards:\n\t#{v.factions.controlling.name} - #{v.factions.controlling.reward}"

            if v.factions.contestant.reward isnt null
                listItem.message += "\n\t#{v.factions.contestant.name} - #{v.factions.contestant.reward}"

            noty.addItem listItem

        return unless count > 0
        noty.show 10

    handle = ( data ) =>
        alerts    = data.Alerts
        invasions = data.Invasions

        newAlerts    = keys( alerts    ).filter ( x ) => x not of local.alerts
        newInvasions = keys( invasions ).filter ( x ) => x not of local.invasions

        newItemsCount += newAlerts.length
        newItemsCount += newInvasions.length if app.experimental

        if app.experimental
            return unless ( newAlerts.length + newInvasions.length ) > 0
        else
            return unless newAlerts.length > 0

        for k in newAlerts
            local.alerts[k] = alerts[k]

        notify.alerts.show newAlerts

        if app.experimental and newItemsCount > 0
            local.invasions = invasions
            notify.invasions.show newInvasions
            sound.play() if app.playSound and Audio? and sound?
            chrome.browserAction.setBadgeText text: newItemsCount.toString()
            Settings.update { local: local }
        else if newItemsCount > 0
            sound.play() if app.playSound and Audio? and sound?
            chrome.browserAction.setBadgeText text: newItemsCount.toString()
            Settings.update { local: local }

    if force is yes or shouldUpdate()
        Api.fetch app.platform, handle

###
    The reload param is for telling the function whether or not
    the extension has already been initialized.
    
    If reload is true, the extension has been loaded once
    and we don't want to call setup() again.
    
    If reload is false, this is the first time the settings
    are being loaded, and we need to run the setup() function.
###
loadConfig = ( reload ) ->
    isSetup = no

    __reload = =>
        if reload is no and isSetup is no
            setup()
            isSetup = yes

    Settings.fetch ( dict ) =>
        unless dict.sync? and keys( dict.sync ).length is keys( appDefaults ).length
            Settings.update { sync: appDefaults }, =>
                app = appDefaults
                __reload()
        else
            app = dict.sync

        unless dict.local? and keys( dict.local ).length is keys( localDefaults ).length
            Settings.update { local: localDefaults }, =>
                local = localDefaults
                __reload()
        else
            local = dict.local
            __reload()

__resetCheck =
    silent: no
    callCount: 1

clearData = ( quick = no ) ->
    unless App.Debug
        return

    if quick is yes and __resetCheck.silent is no
        __resetCheck.silent = yes
    
    if __resetCheck.silent is yes or __resetCheck.callCount % 2 is 0
        Settings.clear => Log.Write "Cleared."
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