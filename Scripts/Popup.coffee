htmlFormat = {
    ###
        Format specifiers:
            {0} = ID
            {1} = the <span> element representing the alert's timer.
            {2} = location in 'Node (Planet)' format
            {3} = level range in 'Lv. X-Y' format, where X is the lower bound, and Y is the upper bound.
            {4} = mission type
            {5} = mission description
            {6} = credit amount.
    ###
    creditOnly: "<table id=\"alerts-table-{0}\" ><!--cellspacing=\"0\" cellpadding=\"3\"-->
    <tr>
        <td class=\"location\">{2} - <em>{3} {4}</em></td>
        <td class=\"time-left\">{1}</td>
    </tr>
    <tr>
        
        <td><em>{5}</em></td>
        <td class=\"credit-reward\">{6}</td>
    </tr>
</table>",

    ###
        Format specifiers:
            {0} = ID
            {1} = the <span> element representing the alert's time
            {2} = location in 'Node (Planet)' format
            {3} = level range in 'Lv. X-Y' format, where X is the lower bound, and Y is the upper bound.
            {4} = mission type
            {5} = other reward type.
            {6} = mission description
            {7} = credit amount.
    ###
    extraReward: "<table id=\"alerts-table-{0}\" ><!--cellspacing=\"0\" cellpadding=\"3\"-->
    <tr>
        <td colspan=\"2\" class=\"time-left\">{1}</td>
    </tr>
    <tr>
        <td class=\"location\">{2} - <em>{3} {4}</em></td>
        <td class=\"other-reward\">
            <span>{5}</span>
        </td>
    </tr>
    <tr>
        <td><em>{6}</em></td>
        <td class=\"credit-reward\">{7}</td>
    </tr>
</table>",
    
    noAlerts: "<table id=\"alerts-table-0\" ><!--cellspacing=\"0\" cellpadding=\"3\"-->
    <tr>
        <td style=\"text-align: center;\"><em>No alerts at this time.</em></td>
    </tr>
</table>",

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
                <img class=\"faction-badge\" src=\"Images/App/{6}.png\" height=\"20\" width=\"20\" />
            </div>
            <div style=\"width: {14}%;\" class=\"progress {15} left\">
                <img class=\"faction-badge\" src=\"Images/App/{3}.png\" height=\"20\" width=\"20\" />
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

makeTimeElement = ( start, expire ) ->
    __now = now()
    html = ""
    
    if expire - __now <= 0
        html = "<span class=\"urgent\">Expired {0} ago</span>".format( timeSpan( Math.abs( expire - __now ) ) )
    else if start > __now
        html = "<span class=\"future\">Starts in {0}</span>".format( timeSpan( Math.abs( start - __now ) ) )
    else
        attr = if expire - __now <= 60 then " class=\"urgent\"" else ""
        html = "<span{0}>{1}</span>".format attr, timeSpan( expire - __now )

    return html

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
                if not owns( x.local.alerts, k ) or k not in trackedAlerts
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
            $( "#alerts-table-{0}".format k ).remove()
            delete trackedAlerts[k]
        else
            $( "#alerts-table-{0} .time-left".format k ).html( makeTimeElement( v.startTime, v.expireTime ) )
        
        if $( "#alerts-container" ).children().length is 0
            $( "#alerts-container" ).html htmlFormat.noAlerts


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
    inner = ""

    for k, v of object
        except =>
            if not owns object, k
                return
                
            diff = v.expireTime - now()

            if diff <= -120
                delete trackedAlerts[k]
                return
                
            if k not in trackedAlerts
                trackedAlerts[k] = v
                
            type = "{0} {1}".format v.faction, v.type
            where = "{0} ({1})".format v.node, v.planet
            range = "Lv. {0}-{1}".format v.levelRange.low, v.levelRange.high
                
            if v.rewards.extra.length > 0
                inner += htmlFormat.extraReward.format( k, makeTimeElement( v.startTime, v.expireTime ), where, range, type, v.rewards.extra[0], v.message, v.rewards.credits )
            else
                inner += htmlFormat.creditOnly.format( k, makeTimeElement( v.startTime, v.expireTime ), where, range, type, v.message, v.rewards.credits )
        
    if inner is ""
        inner = htmlFormat.noAlerts
            
    $( "#alerts-container" ).html inner

injectDebugFeatures = ->
    Log.Error "Only available in debug mode." unless App.Debug

    htmlString = "<div id=\"debug\">
    <button id=\"show-noty\">Show Notification</button>
</div>"

    $( htmlString ).insertAfter $ "#footer"

    $( "#show-noty" ).click =>
        Message.send "DEBUG_NOTIFY"

$( document ).ready =>
    slideOpts =
        duration: 500
        queue: no

    alertsValue = 360
    invasionsValue = 360

    setupExperimental = =>
        $( "#invasions" ).remove()
        $( "#experimental" ).hide()

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
                
                    $( @ ).rotate animateTo: invasionsValue, duration: 900
                
                    if invasionsValue is 360
                        $( "#invasions-container" ).slideDown slideOpts
                    else
                        $( "#invasions-container" ).slideUp slideOpts

    $( "#footer #version" ).text "#{App.Version.toString()} (beta)"
    $( ".year" ).text new Date().getFullYear()

    injectDebugFeatures() if App.Debug

    Message.send "RESET_ALERTS_COUNTER"
    chrome.browserAction.setBadgeText text: ""

    #chrome.runtime.sendMessage action: "RESET_ALERTS_COUNTER", ( response ) =>
    #    if not response? or not response.status? or response.status is no
    #        Log.Error "Invalid message."

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
                
                $( @ ).rotate animateTo: alertsValue, duration: 900
                
                if alertsValue is 360
                    $( "#alerts-container" ).slideDown slideOpts
                else
                    $( "#alerts-container" ).slideUp slideOpts
    
    Settings.fetch ( dict ) =>
        setupExperimental() unless dict.sync.experimental
        $( "#platform" ).text if dict.sync.platform is "XB1" then "Xbox One" else dict.sync.platform

        inner = ""

        buildAlerts    dict.local.alerts
        buildInvasions dict.local.invasions if dict.sync.experimental

        setInterval alertsTracker, 500 #half second
        setInterval invasionsTracker, 60000 if dict.sync.experimental #one minute