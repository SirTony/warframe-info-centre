var settings;

function parseData( str )
{
    var lines = str.split( "\n" );
    
    if( lines.length < 2 )
        return null;
    
    var obj = { };
    
    for( var i = 0; i < lines.length; ++i )
    {
        var parts = lines[i].split( "|" );
        
        if( parts.length < 10 )
            continue;
        
        var creditPlus = parts[9].indexOf( "-" ) !== -1;
        var items      = parts[9].split( " - " );
        
        var subObj = {
            planet:     parts[2],
            node:       parts[1],
            type:       parts[3],
            faction:    parts[4],
            levelRange: {
                low:  parts[5],
                high: parts[6],
            },
            startTime:  parseInt( parts[7] ),
            expireTime: parseInt( parts[8] ),
            rewards: {
                credits: creditPlus ? items[0] : parts[9],
                extra:   creditPlus ? items.slice( 1 ) : [ ]
            },
            message:    parts[10]
        };
        
        obj[parts[0]] = subObj;
    }
    
    return obj;
}

function update()
{
    var lastUpdate;
    
    LocalSettings.getAll( function( x ) { lastUpdate = x.lastUpdate; } );
    
    if( lastUpdate > 0 && now - lastUpdate < settings.updateInverval )
        return false;
    
    //policeOldAlerts();
    
    var url = settings.platform == "PS4" ?
        "http://deathsnacks.com/wf/data/ps4/alerts_raw.txt" :
        "http://deathsnacks.com/wf/data/alerts_raw.txt";
    
    var alerts;
    
    console.log( "Scraping alerts data." );
    $.get( url, function( data ) {
        if( data.length > 0 )
            alerts = parseData( data );
    } );
    
    var localInfo = {
        "alerts":     alerts,
        "lastUpdate": new Date().getTime()
    };
    
    var old = LocalSettings.getAll();
    
    var current   = Object.keys( localInfo.alerts );
    var newAlerts = current.length - old.intersect( current ).length;

    if( newAlerts > 0 )
        chrome.browserAction.setBadgeText( { text: _new.toString() } );
            
    LocalSettings.update( localInfo );
    
    return true;
}

function policeOldAlerts()
{
    chrome.storage.local.get( "alerts", function( dict ) {
        if( typeof chrome.runtime.lastError !== "undefined" )
            console.log( "Error fetching local data: " + chrome.runtime.lastError );
        else
        {
            var now = new Date().getTime();
            var queue = [ ];
            
            for( var key in dict.alerts )
            {
                if( !dict.alerts.hasOwnProperty( key ) )
                    continue;
                
                if( dict.alerts[key].expireTime <= now )
                    queue.push( key );
            }
            
            if( queue.length > 0 )
                chrome.storage.local.remove( queue, function() {
                    if( typeof chrome.runtime.lastError !== "undefined" )
                        console.log( "Error removing local data: " + chrome.runtime.lastError );
                } );
        }
    } );
}

function setup()
{
    if( !AppSettings.verify() || AppSettings.isFirstRun() )
        AppSettings.install();

    if( !LocalSettings.verify() )
        LocalSettings.install();
        settings = AppSettings.getByName( "lastUpdate", "platform" );
    
    chrome.runtime.onMessage.addListener( function( request, sender, sendResponse ) {
        var success = false;
        
        /*if( sender.id !== "nbhldmoaibnkmjcbkkenchhicdodemnm" )
            sendResponse( { result: "FAIL" } );
        else*/ if( typeof request.action !== "undefined" )
            sendResponse( { result: "NO_ACTION" } );
        else if( request.action === "UPDATE_CONFIG" )
        {
            success = loadConfig();
            
            if( !success )
                sendResponse( { result: "FAIL" } );
            else
                sendResponse( { result: "OK" } );
        }
        else if( request.action === "UPDATE_NOW" )
        {
            success = loadConfig() && update();
            
            if( !success )
                sendResponse( { result: "FAIL" } );
            else
                sendResponse( { result: "OK" } );
        }
        else sendResponse( { result: "UNKNOWN_ACTION" } );
        
        return success;
    } );
    
    update();
    setInterval( update, settings.updateInterval * 1000 );
}

setup();