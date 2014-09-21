htmlFormat = {
    ###
        {0}  - ID
        {1}  - Location
        {2}  - Type
        {3}  - Defending faction
        {4}  - Defending level range
        {5}  - Defending mission type
        {6}  - Attacking faction
        {7}  - Attacking level range
        {8}  - Attacking mission type
        {9}  - Score (in current/required format)
        {10} - How long the invasion has been active
        {11} - Estimated time to completion.
        {12} - Attacking faction completion percent.
        {13} - Attacking faction CSS class.
        {14} - Defending faction completion percent.
        {15} - Defending faction CSS class.
        {16} - Rewards.
    ###
    invasion: "<table title=\"Click for more information.\" class=\"ai-conflict\" id=\"invasion-table-{0}\" ><!--cellpadding=\"3\" cellspacing=\"0\" border=\"0\"-->
    <tr>
        <th colspan=\"2\" class=\"centre\">{1} <em class=\"extra\">- {2}</em></th>
    </tr>
    <tr>
        <td colspan=\"2\" class=\"centre\">
            <strong>{3}</strong> <span class=\"extra\">{4} ({5})</span>
            <strong>vs.</strong>
            <strong>{6}</strong> <span class=\"extra\">{7} ({8})</span> - {12}%</td>
    </tr>
    <tr id=\"score\" class=\"extra\">
        <td colspan=\"2\" class=\"centre\"><em>Score: {9} | Active for: {10} | {11}</em></td>
    </tr>
    <tr>
        <td colspan=\"2\">
            <div style=\"width: {12}%;\" class=\"progress {13} right\">
                <img class=\"faction-badge\" src=\"../Images/App/{6}.png\" height=\"20\" width=\"20\" />
            </div>
            <div style=\"width: {14}%;\" class=\"progress {15} left\">
                <img class=\"faction-badge\" src=\"../Images/App/{3}.png\" height=\"20\" width=\"20\" />
            </div>
        </td>
    </tr>
    {16}
</table>",

    noInvasions: "<table id=\"invasion-table-0\" ><!--cellspacing=\"0\" cellpadding=\"3\"-->
    <tr>
        <td style=\"text-align: center;\"><em>No invasions at this time.</em></td>
    </tr>
</table>",

}

trackedAlerts = {}
trackerTicks = 0

makeTimeElement = ( start, expire, asDOM = no ) ->
    timeTemplate = Template.fetch "timeElement", no, yes
    timeTemplate.registerFilter "formatTime", ( x ) => timeSpan Math.abs parseInt x

    timeData =
        Class:    if expire - now() <= 60 then "urgent" else if start > now() then "future" else ""
        TimeLeft: expire - now()

    rendered = timeTemplate.render timeData
    return if asDOM then $ rendered else rendered

invasionsTracker = ->
    ###
        Invasions are re-built completely every 60 seconds.
    ###
    Settings.fetch ( x ) => buildInvasions x.local.invasions

alertsTracker = ->
    ###
        Every 10 seconds we poll LocalSettings to check if there are any new alerts.
        If there are, we rebuild the alert section HTML to put it in the list while
        the popup window is open. The HTML will only be re-built if a new alert is
        detected, not every 10 seconds.
        ---
        trackerTicks is incremented once every time setInterval() invokes alertsTracker()
        since the time on setInterval() is set to 500ms/0.5s, 20 ticks = 10 seconds.
    ###
    if trackerTicks is 20
        trackerTicks = 0

        Settings.fetch ( x ) =>
            __new = 0
            for k, v of x.local.alerts
                if not owns( x.local.alerts, k ) or k not of trackedAlerts
                    continue
                else
                    trackedAlerts[k] = v
                    ++__new

            if __new > 0
                buildAlerts trackedAlerts

    else
        ++trackerTicks

    for k, v of trackedAlerts
        if not owns trackedAlerts, k
            continue
        
        if v.expireTime - now() <= -120
            $( "#alerts-table-#{k}" ).remove()
            delete trackedAlerts[k]
        else
            $( "#alerts-container #alerts-table-#{k} .time-left" ).html makeTimeElement v.startTime, v.expireTime
        
        if $( "#alerts-container" ).children().length is 0
           $( "#alerts-container" ).html Template.load "alerts", NoAlerts: yes


buildInvasions = ( object ) ->
    inner = ""

    for k, v of object
        if not owns object, k
            continue

        attacker = if v.factions.contestant.name is "Infestation" then "Infested" else v.factions.contestant.name
        percent = if v.score.current < 0 then 100.0 - v.score.percent else v.score.percent

        if Math.abs( v.score.current ) >= v.score.goal
            continue

        rewards = ""

        if attacker is "Infested"
            rewards = "<tr colspan=\"2\">
    <td class=\"text-left\">
        <span class=\"round light\">#{v.factions.controlling.reward}</span>
    </td>
</tr>"
        else
            rewards = "<tr>
    <td class=\"text-left\">
        <span class=\"round light\">#{v.factions.controlling.reward}</span>
    </td>
    <td class=\"text-right\">
        <span class=\"round light\">#{v.factions.contestant.reward}</span>
    </td>
</tr>"

        #TODO: switch attacker/defender sides.
        inner += htmlFormat.invasion.format(
            k,
            "{0} ({1})".format( v.node, v.planet ),
            v.message,
            v.factions.controlling.name,
            "Lv. {0}-{1}".format( v.factions.controlling.levelRange.low, v.factions.controlling.levelRange.high ),
            v.factions.controlling.missionType,
            attacker,
            "Lv. {0}-{1}".format( v.factions.contestant.levelRange.low, v.factions.contestant.levelRange.high ),
            v.factions.contestant.missionType,
            "{0}/{1}".format( v.score.current, v.score.goal ),
            timeSpan( Math.abs( now() - v.startTime ) ),
            v.eta,
            percent.toFixed( 2 ),
            attacker.toLowerCase(),
            100.0 - percent,
            v.factions.controlling.name.toLowerCase(),
            rewards
        )

    if inner is ""
        inner = htmlFormat.noInvasions

    $( "#invasions-container" ).html inner

buildAlerts = ( object ) ->
    $( "#alerts-container table" ).remove();

    for k, v of object
        continue unless owns object, k

        except =>
            diff = v.expireTime - now()

            if diff <= -120
                delete trackedAlerts[k]
                return

            trackedAlerts[k] = v

            templateData =
                NoAlerts:  no
                ID:        k
                Node:      v.node
                Planet:    v.planet
                Faction:   v.faction
                Type:      v.type
                LevelMin:  v.levelRange.low
                LevelMax:  v.levelRange.high
                Desc:      v.message
                Credits:   v.rewards.credits
                Rewards:   if v.rewards.extra is null or v.rewards.length is 0 then 0 else v.rewards.extra

            $( "#alerts-container" ).append Template.load "alerts", templateData
            $( "#alerts-container #alerts-table-#{k} .time-left" ).html makeTimeElement v.startTime, v.expireTime

injectDebugFeatures = ->
    Log.Error "Only available in debug mode." unless App.Debug

    $( Template.fetch "debug", yes ).insertAfter $ "#footer"

    $( "#show-noty" ).click =>
        Message.send "DEBUG_NOTIFY"

    $( "#play-sound" ).click =>
        Message.send "DEBUG_SOUND"

$( document ).ready =>
    combyne.settings.delimiters =
        START_RAW:  "[["
        END_RAW:    "]]"
        START_PROP: "{{"
        END_PROP:   "}}"
        START_EXPR: "{%"
        END_EXPR:   "%}"
        COMMENT:    "#"
        FILTER:     "->"

    platformImages =
        Normal:
            PC: "PC.Normal.png"
            PS4: "PS4.Normal.png"
            XB1: "XboxOne.Normal.png"
        Experimental:
            PC: "PC.Experimental.png"
            PS4: "PS4.Experimental.png"
            XB1: "XboxOne.Experimental.png"

    slideOpts =
        duration: 500
        queue: no

    alertsValue = 360
    invasionsValue = 360

    setupExperimental = ( platform ) =>
        $( "#invasions" ).hide()
        $( "#platform" ).attr "src", "../Images/App/#{platformImages.Normal[platform]}"
        $( "#platform" ).attr "src", "#{if platform is 'XB1' then 'Xbox One' else platform}"

    $( "#footer #version" ).text "#{App.Version.toString()} (beta)"
    $( ".year" ).text new Date().getFullYear()

    injectDebugFeatures() if App.Debug

    Message.send "RESET_ALERTS_COUNTER"
    chrome.browserAction.setBadgeText text: ""

    $( "#alerts-expander" ).rotate alertsValue
    $( "#alerts-expander" ).rotate
        bind:
            click: ->
                if alertsValue is 180
                    alertsValue = 360
                else if alertsValue is 360
                    alertsValue = 180
                else
                    alertsValue = 360
                
                $( "#alerts-expander" ).rotate animateTo: alertsValue, duration: 900
                
                if alertsValue is 360
                    $( "#alerts-container" ).slideDown slideOpts
                else
                    $( "#alerts-container" ).slideUp slideOpts

    $( "#invasions-expander" ).rotate invasionsValue
    $( "#invasions-expander" ).rotate
        bind:
            click: ->
                if invasionsValue is 180
                    invasionsValue = 360
                else if invasionsValue is 360
                    invasionsValue = 180
                else
                    invasionsValue = 360
                
                $( "#invasions-expander" ).rotate animateTo: invasionsValue, duration: 900
                
                if invasionsValue is 360
                    $( "#invasions-container" ).slideDown slideOpts
                else
                    $( "#invasions-container" ).slideUp slideOpts
    
    Settings.fetch ( dict ) =>
        unless dict.sync.experimental
            setupExperimental( dict.sync.platform )
        else
            $( "#platform" ).attr "src", "../Images/App/#{platformImages.Experimental[dict.sync.platform]}"
            $( "#platform" ).attr "alt", "#{if dict.sync.platform is 'XB1' then 'Xbox One' else dict.sync.platform} (Experimental)"

        inner = ""

        buildAlerts    dict.local.alerts
        buildInvasions dict.local.invasions if dict.sync.experimental

        setInterval alertsTracker, 500 #half second
        setInterval invasionsTracker, 60000 if dict.sync.experimental #one minute