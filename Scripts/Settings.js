var blueprintIds = [
    "silver-potato-bp", "golden-potato-bp", "forma-bp",
    "forma-whole", "ash-scorpion-bp", "ash-locust-bp",
    "banshee-reverb-bp", "banshee-chorus-bp", "ember-phoenix-bp",
    "ember-backdraft-bp", "excal-avalon-bp", "excal-pendragon-bp",
    "frost-aurora-bp", "frost-squall-bp", "hydroid-triton-bp",
    "loki-essence-bp", "loki-swindle-bp", "mag-coil-bp",
    "mag-gauss-bp", "nakros-raknis-bp", "nekros-shroud-bp",
    "nova-flux-bp", "nova-quantum-bp", "nyx-menticide-bp",
    "nyx-vespa-bp", "oberon-oryx-bp", "oberon-markhor-bp",
    "rhino-thrak-bp", "rhino-vanguard-helmet-bp", "saryn-hemlock-bp",
    "saryn-chlora-bp", "trinity-aura-bp", "trinity-meridian-bp",
    "valkyr-bastet-bp", "valkyr-kara-bp", "vauban-esprit-bp",
    "vauban-gambit-bp", "vauban-chassis-bp", "vauban-helmet-bp",
    "vauban-systems-bp", "volt-storm-bp", "volt-pulse-bp",
    "zephyr-cierzo-bp", "heatsword-bp", "heatdagger-bp",
    "darksword-bp", "dakdagger-bp", "jawsword-bp",
    "manticore-bp", "brokk-bp", "zoren-dagger-bp", 
    "scindo-dagger-bp"
];

var modIds = [
    "constitution-mod", "fortitude-mod", "hammershot-mod",
    "wildfire-mod", "acceleratedblast-mod", "blaze-mod",
    "icestorm-mod", "stunningspeed-mod", "focusenergy-mod",
    "rendingstrike-mod", "vigour-mod", "shred-mod",
    "lethaltorrent-mod"
];

var resourceIds = [
    "morphics-mat", "orokincell-mat",
    "gallium-mat", "controlmod-mat",
    "neuralsens-mat", "neurode-mat",
    "circuits-mat", "rubedo-mat",
    "plastids-mat", "ferrite-mat",
    "alloy-mat", "nano-mat",
    "polymer-mat", "salvage-mat"
];

function saveSettings()
{
    var interval = parseInt( $( "#update-interval" ).val() );
    var cash     = parseInt( $( "#money-amount" ).val() );
    
    if( typeof interval !== "number" )
        interval = 60;
        
    if( typeof cash !== "number" )
        cash = 5000;
    
    var bp = blueprintIds.map( function( id ) {
        return $( "#" + id );
    } ).filter( function( item ) {
        return item.is( ":checked" ) === true;
    } ).map( function( item ) {
        return {
            ID: item.attr( "id" ),
            Value: item.val()
        };
    } );
    
    var mod = modIds.map( function( id ) {
        return $( "#" + id );
    } ).filter( function( item ) {
        return item.is( ":checked" ) === true;
    } ).map( function( item ) {
        return {
            ID: item.attr( "id" ),
            Value: item.val()
        };
    } );
    
    var mats = resourceIds.map( function( id ) {
        return $( "#" + id );
    } ).filter( function( item ) {
        return item.is( ":checked" ) === true;
    } ).map( function( item ) {
        return {
            ID: item.attr( "id" ),
            Value: item.val()
        };
    } );
    
    var dict = {
        platform: $( "#platform-selector" ).val(),
        updateInterval: interval.between( 60, 500 ) ? interval : 60,
        //notify: $( "#show-notifications" ).is( ":checked" ),
        alerts: {
            showCreditOnly: $( "#money-alert" ).is( ":checked" ),
            minimumCash: cash.between( 1, 99999 ) ? cash : 5000,
            showBlueprint: $( "#track-blueprints" ).is( ":checked" ),
            showNightmare: $( "#track-nightmare-mods" ).is( ":checked" ),
            showResource:  $( "#track-resources" ).is( ":checked" )
        },
        blueprints: bp,
        mods: mod,
        resources: mats
    };
    
    try
    {
        AppSettings.update( dict );
    }
    catch( e )
    {
        console.log( e );
        alert( "Settings could not be updated. Please try again in a few moments." );
    }
}

function displaySettings()
{
    var items = null;
    
    AppSettings.getAll( function ( x ) { items = x; } );
    
    if( items === null )
        throw "Could not retrieve settings.";
        
    $( "#platform-selector" ).val( items.platform );
    $( "#update-interval" ).val( items.updateInterval );
    $( "#show-notifications" ).prop( "checked", items.notify );
    $( "#money-alert" ).prop( "checked", items.alerts.showCreditOnly );
    $( "#money-amount" ).val( items.alerts.minimumCash );
    $( "#track-blueprints" ).prop( "checked", items.alerts.showBlueprint );
    $( "#track-nightmare-mods" ).prop( "checked", items.alerts.showNightmare );
    $( "#track-resources" ).prop( "checked", items.alerts.showResource );
    
    for( var i = 0; i < items.blueprints.length; ++i )
        $( "#" + items.blueprints[i].ID ).prop( "checked", true );
    
    for( i = 0; i < items.mods.length; ++i )
        $( "#" + items.mods[i].ID ).prop( "checked", true );
    
    for( i = 0; i < items.resources.length; ++i )
        $( "#" + items.resources[i].ID ).prop( "checked", true );
    
    if( $( "#track-blueprints" ).is( ":checked" ) === true )
        $( "#blueprint-table" ).show();
    else
        $( "#blueprint-table" ).hide();
    
    if( $( "#track-nightmare-mods" ).is( ":checked" ) === true )
        $( "#mod-table" ).show();
    else
        $( "#mod-table" ).hide();
        
    if( $( "#track-resources" ).is( ":checked" ) === true )
        $( "#resource-table" ).show();
    else
        $( "#resource-table" ).hide();
}

function checkAllBlueprints( checked )
{
    for( var i = 0; i < blueprintIds.length; ++i )
        $( "#" + blueprintIds[i] ).prop( "checked", checked );
}

function checkAllMods( checked )
{
    for( var i = 0; i < modIds.length; ++i )
        $( "#" + modIds[i] ).prop( "checked", checked );
}

function checkAllResources( checked )
{
    for( var i = 0; i < resourceIds.length; ++i )
        $( "#" + resourceIds[i] ).prop( "checked", checked );
}

$( document ).ready( function() {
    $( "#save-button" ).click( saveSettings );
    
    $( "#bp-check-all" ).click( function() { checkAllBlueprints( true ); } );
    $( "#mod-check-all" ).click( function() { checkAllMods( true ); } );
    $( "#mats-check-all" ).click( function() { checkAllResources( true ); } );
    
    $( "#bp-uncheck-all" ).click( function() { checkAllBlueprints( false ); } );
    $( "#mod-uncheck-all" ).click( function() { checkAllMods( false ); } );
    $( "#mats-uncheck-all" ).click( function() { checkAllResources( false ); } );
    
    $( "#track-blueprints" ).change( function() {
        if( $( "#track-blueprints" ).is( ":checked" ) === true )
            $( "#blueprint-table" ).show();
        else
            $( "#blueprint-table" ).hide();
    } );
    
    $( "#track-nightmare-mods" ).change( function() {
        if( $( "#track-nightmare-mods" ).is( ":checked" ) === true )
            $( "#mod-table" ).show();
        else
            $( "#mod-table" ).hide();
    } );
    
    $( "#track-resources" ).change( function() {
        if( $( "#track-resources" ).is( ":checked" ) === true )
            $( "#resource-table" ).show();
        else
            $( "#resource-table" ).hide();
    } );
    
    try
    {
        displaySettings();
        
        if( AppSettings.verify() === false || AppGettings.isFirstRun() === true )
            AppSettings.install();
    }
    catch( e )
    {
        console.log( e );
        alert( "There was an error retreiving settings. Please try again in a few moments." );
    }
} );