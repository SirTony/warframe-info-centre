app   = null;
local = null;
url   = null;

appDefaults = {
    platform: "PC",
    updateInterval: 60,
    
    #These following 3 settings exist for forward-compatibility,
    #and are not actually implemented in the code at all.
    notify: yes,
    playSound: no,
    customSound: null,
    # /end
    
    alerts: {
        showCreditOnly: yes,
        minimumCash: 5000,
        showBlueprint: no,
        showNightmare: no,
        showResource:  ( no )
    },
    blueprints: [ ],
    mods: [ ],
    resources: [ ]
}

localDefaults = {
    alerts: { },
    lastUpdate: ( null )
}

shouldUpdate = ->
    console.trace "Checking update status."
    local.lastUpdate is null or now() - local.lastUpdate >= app.updateInterval

setup = ->
    console.trace "Setting up extension."
    
    url = if app.platform is "PS4" then \
    "http://deathsnacks.com/wf/data/ps4/alerts_raw.txt" \
    else \
    "http://deathsnacks.com/wf/data/alerts_raw.txt"
    
    if shouldUpdate()
        update()
    
    setTimeout update, ( app.updateInterval * 1000 ) - 100
    return

policeOldAlerts = ->
    for k, v of local.alerts
        if not local.alerts.hasOWnProperty k
            continue
        
        __now = now()
        
        if v.expireTime - __now <= 0
            delete local.alerts[k]

update = ->
    console.trace "Running updater."
    
    if shouldUpdate()
        console.trace "Updating."
        
        httpGet url, ( resp ) ->
            console.trace( "Fetched data." );
            console.trace( resp );
            console.trace( resp.length );
            
            if resp.length > 0
                newAlerts = parseData resp
                local.lastUpdate = now()
                
                currentKeys = local.alerts.keys()
                newKeys = newAlerts.keys().filter ( x ) -> not ( x in currentKeys )
                
                if newKeys.length > 0
                    chrome.browserAction.setBadgeText { text: newKeys.length.toString() }
                
                for k, v of newAlerts
                    if newAlerts.hasOwnProperty k
                        local.alerts[k] = v
                
                LocalSettings.update local, ->
                    console.log "Updated local settings."
                    
            return
        return
    else
        console.trace "No need to update."
    return

parseData = ( text ) ->
    console.trace "Parsing alerts data."
    
    lines = text.split "\n"
    
    if lines.length < 2
        return null;
    
    alerts = { }
    
    for line in lines
        parts = line.split "|"
        
        if parts.length < 10
            continue
        
        creditPlus = not ( parts[9].indexOf( "-" ) is -1 )
        items      = parts[9].split " - "
        
        obj = {
            planet: parts[2],
            node: parts[1],
            type: parts[3],
            faction: parts[4],
            
            levelRange: {
                low: parts[5],
                high: parts[6]
            },
            
            startTime: parseInt( parts[7] ),
            expireTime: parseInt( parts[8] ),
            
            rewards: {
                credits: if creditPlus is yes then items[0] else parts[9],
                extra:   if creditPlus is yes then items.slice 1 else [ ]
            }
            
            message: parts[10]
        }
        
        alerts[parts[0]] = obj
    
    return alerts

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
                AppSettings.getValues "platform", "updateInterval", ( appRes2 ) ->
                    app = appRes2
                    return
                return
        else
            app = appRes.selectKeys "platform", "updateInterval"
        
        LocalSettings.getAll ( locRes ) ->
            if isUndefined( locRes ) or locRes is null or not ( locRes.keys().length is localDefaults.keys().length )
                LocalSettings.update localDefaults, ->
                    LocalSettings.getAll ( locRes2 ) ->
                        local = locRes2
                    
                        if( reload is no )
                            setup()
                            return
                    return
            else
                local = locRes
                
                if( reload is no )
                    setup()
            
            return
        return
    return

__resetCheck = {
    silent: no,
    callCount: 1
}

clearData = ( quick = no ) ->
    if( quick is yes and __resetCheck.silent is no )
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
    loadConfig no;
catch e
    type = Exception.getType e
    if type is ( null )
        console.error e.stack.toString()
    else
        console.error "{0}: {1}".format type, e.getMessage()
