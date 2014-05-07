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
    creditOnly: "<table id=\"alerts-table-{0}\" cellspacing=\"0\" cellpadding=\"3\">
    <tr>
        <td class=\"location\">{2} - <em>{3} {4}</em></td>
        <td class=\"time-left\">{1}</td>
    </tr>
    <tr>
        
        <td><em>{5}</em></td>
        <td class=\"credit-reward\">{6}</td>
    </tr>
</table>"

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
    extraReward: "<table id=\"alerts-table-{0}\" cellspacing=\"0\" cellpadding=\"3\">
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
</table>"
    
    noAlerts: "<table id=\"alerts-table-0\" cellspacing=\"0\" cellpadding=\"3\">
    <tr>
        <td style=\"text-align: center;\"><em>No alerts at this time.</em></td>
    </tr>
</table>"
}

tracked = { }

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

tracker = ->
    for k, v of tracked
        if not tracked.hasOwnProperty k
            continue
        
        if v.expire - now() <= -120
            $( "#alerts-table-{0}".format k ).remove()
            delete tracked[k]
        else
            $( "#alerts-table-{0} .time-left".format k ).html( makeTimeElement( v.start, v.expire ) )
        
        if $( "#alerts-container" ).children().length is 0
            $( "#alerts-container" ).html htmlFormat.noAlerts
        
    return

$( document ).ready ->
    chrome.browserAction.setBadgeText { text: "" }
    
    alertsValue = 360 #invasionsValue = 360
    
    $( "#alerts-expander" ).rotate alertsValue
    #$( "#invasions-expander" ).rotate invasionsValue
    
    slideOpts = {
        duration: 500,
        queue: ( no )
    }
    
    $( "#alerts-expander" ).rotate {
        bind: {
            click: ->
                if alertsValue is 180
                    alertsValue = 360
                else if alertsValue is 360
                    alertsValue = 180
                else
                    alertsValue = 360
                
                $( @ ).rotate { animateTo: alertsValue, duration: 900 }
                
                if alertsValue is 360
                    $( "#alerts-container" ).slideDown slideOpts
                    return
                else
                    $( "#alerts-container" ).slideUp slideOpts
                    return
        }
    }
    
    ###
    $( "#invasions-expander" ).rotate {
        bind: {
            click: ->
                if invasionsValue is 180
                    invasionsValue = 360
                else if invasionsValue is 360
                    invasionsValue = 180
                else
                    invasionsValue = 360
                
                $( @ ).rotate { animateTo: invasionsValue, duration: 900 }
                
                if invasionsValue is 360
                    $( "#invasions-container" ).slideDown slideOpts
                    return
                else
                    $( "#invasions-container" ).slideUp slideOpts
                    return
        }
    }
    ###
    
    LocalSettings.getAll ( x ) ->
        inner = ""
        
        console.log x.alerts
        
        for k, v of x.alerts
            try
                if not x.alerts.hasOwnProperty( k )
                    console.log "Bad key."
                    continue
                
                console.log "Building alert " + k
                
                diff = v.expireTime - now()
                
                if diff <= -120
                    console.log "Old alert ({0}). Expires: {1} ({2}); Now: {3} ({4}).".format k, v.expireTime, new Date( v.expireTime * 1000 ), now(), new Date( now() * 1000 )
                    continue
                else
                    console.log "Expires: {1} ({2}); Now: {3} ({4}).".format v.expireTime, new Date( v.expireTime ), now(), new Date( now() * 1000 )
                
                tracked[k] = { start: v.startTime, expire: v.expireTime }
                
                type = "{0} {1}".format v.faction, v.type
                where = "{0} ({1})".format v.node, v.planet
                range = "Lv. {0}-{1}".format v.levelRange.low, v.levelRange.high
                
                if v.rewards.extra.length > 0
                    inner += htmlFormat.extraReward.format( k, makeTimeElement( v.startTime, v.expireTime ), where, range, type, v.rewards.extra[0], v.message, v.rewards.credits ) 
                else
                    inner += htmlFormat.creditOnly.format( k, makeTimeElement( v.startTime, v.expireTime ), where, range, type, v.message, v.rewards.credits ) 
            catch e
                console.log e.stack.toString()

        console.log( if inner is "" then "<Empty>" else inner )
        
        if inner is ""
            inner = htmlFormat.noAlerts
            
        $( "#alerts-container" ).html inner
        setInterval tracker, 500
    return
