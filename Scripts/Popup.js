var alerts;
var updateInterval;

function updateClocks()
{
}

function updateHtml()
{
    var noAlerts = "<table id=\"alerts-table-0\" cellspacing=\"0\" cellpadding=\"3\"><tr><td style=\"text-align: center;\"><em>No alerts at this time.</em></td></tr></table>";
    
    chrome.storage.local.get( [ "alerts", "lastUpdate" ], function( dict ) {
        if( typeof chrome.runtime.lastError !== "undefined" )
        {
            console.log( "Error fetching local data: " + chrome.runtime.lastError );
            $( "#alerts-container" ).html( noAlerts );
            return;
        }
        
        if( Object.keys( dict ).length < 2 )
        {
            chrome.runtime.sendMessage( { action: "UPDATE_NOW" } );
            updateHtml();
            return;
        }
        
        console.log( "poop" );
        console.log( dict );
        var now  = new Date().getTime();
        var keys = Object.keys( dict.alerts );
        
        if( keys.length === 0 )
            $( "#alerts-container" ).html( noAlerts );
        else
        {
            $( "#alerts-container" ).html( "<h1>ass</h1>" );
        }
    } );
}

$( document ).ready( function() {
    chrome.browserAction.setBadgeText( { text: "" } );
    
    var value = 0;
    $( "#alerts-expander" ).rotate( {
        bind: {
            click: function() {
                if( value === 180 )
                    value = 0;
                else if( value === 0 )
                    value = 180;
                else
                    value = 0;
                
                $( this ).rotate( { animateTo: value, duration: 1250 } );
                
                //*
                var slideOpts = {
                    duration: 500,
                    queue: false,
                }
                
                if( value === 0 )
                    $( "#alerts-container" ).slideDown( slideOpts );
                else
                    $( "#alerts-container" ).slideUp( slideOpts );
                //*/
            }
        }
    } );
    
    chrome.storage.sync.get( "updateInterval", function( dict ) {
        updateInterval = ( dict.updateInterval * 1000 ) - 10;
        updateHtml();
        //setInterval( updateClocks, 500 );
        //setInterval( updateHtml, time );
    } );
} );