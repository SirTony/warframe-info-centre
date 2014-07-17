blueprintIds = [
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
]

modIds = [
    "constitution-mod", "fortitude-mod", "hammershot-mod",
    "wildfire-mod", "acceleratedblast-mod", "blaze-mod",
    "icestorm-mod", "stunningspeed-mod", "focusenergy-mod",
    "rendingstrike-mod", "vigour-mod", "shred-mod",
    "lethaltorrent-mod"
]

resourceIds = [
    "morphics-mat", "orokincell-mat",
    "gallium-mat", "controlmod-mat",
    "neuralsens-mat", "neurode-mat",
    "circuits-mat", "rubedo-mat",
    "plastids-mat", "ferrite-mat",
    "alloy-mat", "nano-mat",
    "polymer-mat", "salvage-mat"
]

getCheckedOf = ( what ) ->
    return what.map( ( id ) -> $( "#" + id ) ).filter( ( x ) -> x.is( ":checked" ) is yes ).map( ( x ) -> { ID: x.attr( "id" ), Value: x.val() } )

save = ->
    interval = parseInt( $( "#update-interval" ).val() )
    cash     = parseInt( $( "#money-amount" ).val() )
    
    if not isNumber( interval ) or isNaN( interval )
        interval = 60
    
    if not isNumber( cash ) or isNaN( cash )
        cash = 5000
    
    dict = {
        platform: $( "#platform-selector" ).val(),
        updateInterval: if interval.between( 60, 500 ) then interval else 60,
        experimental: $( "#experimental" ).is( ":checked" ),
        notify: $( "#show-notifications" ).is( ":checked" ),
        noSpam: $( "#notify-spam" ).is( ":checked" ),
        playSound: $( "#play-sound" ).is( ":checked" ),
        soundFile: $( "#mp3-source" ).prop( "src" ),
        alerts: {
            showCreditOnly: $( "#money-alert" ).is( ":checked" ),
            minimumCash: if cash.between( 1, 99999 ) then cash else 5000,
            showBlueprint: $( "#track-blueprints" ).is( ":checked" ),
            showNightmare: $( "#track-nightmare-mods" ).is( ":checked" ),
            showResource:  $( "#track-resources" ).is( ":checked" )
        },
        blueprints: getCheckedOf( blueprintIds ),
        mods: getCheckedOf( modIds ),
        resources: getCheckedOf( resourceIds )
    }
    
    except =>
        AppSettings.update dict, =>
            Message.send "UPDATE_SETTINGS"
            ###
            chrome.runtime.sendMessage { action: "UPDATE_SETTINGS", config: dict }, ( response ) ->
                if response.status is ( yes )
                    console.log "Updated settings."
                else
                    console.error "Update settings failed.\n" + response.message
            ###
            alert "Settings saved successfully."

display = ->
    AppSettings.getAll ( config ) ->
        $( "#platform-selector" ).val config.platform
        $( "#update-interval" ).val config.updateInterval
        $( "#experimental" ).prop "checked", config.experimental
        $( "#show-notifications" ).prop "checked", config.notify
        $( "#notify-spam" ).prop "checked", config.noSpam
        $( "#play-sound" ).prop "checked", config.playSound
        $( "#money-alert" ).prop "checked", config.alerts.showCreditOnly
        $( "#money-amount" ).val config.alerts.minimumCash
        $( "#track-blueprints" ).prop "checked", config.alerts.showBlueprint
        $( "#track-nightmare-mods" ).prop "checked", config.alerts.showNightmare
        $( "#track-resources" ).prop "checked", config.alerts.showResource
        
        __all = [].concat config.blueprints, config.mods, config.resources
        
        for x in __all
            console.log x
            $( "#" + x.ID ).prop "checked", (yes)
        ###
        if config.alerts.showBlueprint is (yes)
            $( "#blueprint-table" ).show()
        else
            $( "#blueprint-table" ).hide()
        
        if config.alerts.showNightmare is (yes)
            $( "#mod-table" ).show()
        else
            $( "#mod-table" ).hide()
        
        if config.alerts.showResource is (yes)
            $( "#resource-table" ).show()
        else
            $( "#resource-table" ).hide()
        ###
        $( "#mp3-source" ).attr( "src", config.soundFile ).detach().appendTo "#audio-preview"
        
        if config.soundFile.indexOf( "chrome-extension://" ) is 0 #Default MP3
            fileName = config.soundFile.split( "/" ).slice( -1 ).pop()
            $( "#default-sounds" ).val decodeURIComponent fileName
        else
            $( "#default-sounds" ).val "user-defined"
        
checkAllBlueprints = ( c ) ->
    for x in blueprintIds
        $( "#" + x ).prop "checked", c

checkAllMods = ( c ) ->
    for x in modIds
        $( "#" + x ).prop "checked", c

checkAllResources = ( c ) ->
    for x in resourceIds
        $( "#" + x ).prop "checked", c

$( document ).ready ->
    $( "#save-button" ).click save
    
    $( "#bp-check-all" ).click -> checkAllBlueprints (yes)
    $( "#mod-check-all" ).click -> checkAllMods (yes)
    $( "#mats-check-all" ).click -> checkAllResources (yes)
    
    $( "#bp-uncheck-all" ).click -> checkAllBlueprints (no)
    $( "#mod-uncheck-all" ).click -> checkAllMods (no)
    $( "#mats-uncheck-all" ).click -> checkAllResources (no)

    $( "#track-blueprints" ).change ->
        if $( "#track-blueprints" ).is ":checked"
            $( "#blueprint-table" ).show()
        else
            $( "#blueprint-table" ).hide()
    
    $( "#track-nightmare-mods" ).change ->
        if $( "#track-nightmare-mods" ).is ":checked"
            $( "#mod-table" ).show()
        else
            $( "#mod-table" ).hide()
    
    $( "#track-resources" ).change ->
        if $( "#track-resources" ).is ":checked"
            $( "#resource-table" ).show()
        else
            $( "#resource-table" ).hide()

    $( "#default-sounds" ).change ->
        if $( "#default-sounds :selected" ).val() is "user-defined"
            $( "#default-sounds-cell" ).hide()
            $( "#user-sound-cell" ).show()

    $( "#soundfile" ).change ->
        file = document.getElementById( "soundfile" ).files[0]
        
        if not ( file.type is "audio/mp3" )
            alert "Warframe Info Centre only accepts MP3 audio files."
            $( "#soundfile" ).replaceWith( $( "#soundfile" ).clone true )

    $( "#cancel-upload" ).click ->
        $( "#user-sound-cell" ).hide()
        $( "#default-sounds-cell" ).show()

    $( "#do-play-sound" ).click ->
        option = $( "#default-sounds :selected" ).val()

        if option is "user-defined"
            return

        option = encodeURIComponent option
        path = chrome.extension.getURL "/Audio/#{option}"
        $( "#mp3-source" ).attr( "src", path ).detach().appendTo "#audio-preview"
        document.getElementById( "audio-preview" ).play()

    display()