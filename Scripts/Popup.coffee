htmlFormat = {
    ###
        Format specifiers:
            {0} = ID
            {1} = Optional attributes for the time-left <span>
            {2} = time left, expressed in 'h m s' format
            {3} = location in 'Node (Planet)' format
            {4} = level range in 'Lv. X-Y' format, where X is the lower bound, and Y is the upper bound.
            {5} = mission type
            {6} = mission description
            {7} = credit amount.
    ###
    creditOnly: "<table id=\"alerts-table-{0}\" cellspacing=\"0\" cellpadding=\"3\">
    <tr>
        <td class=\"location\">{3} - <em>{4} {5}</em></td>
        <td class=\"time-left\"><span{1}>{2}</span></td>
    </tr>
    <tr>
        
        <td><em>{6}</em></td>
        <td class=\"credit-reward\">{7}</td>
    </tr>
</table>"

    ###
        Format specifiers:
            {0} = ID
            {1} = Optional attributes for the time-left <span>
            {2} = time left, expressed in 'h m s' format
            {3} = location in 'Node (Planet)' format
            {4} = level range in 'Lv. X-Y' format, where X is the lower bound, and Y is the upper bound.
            {5} = mission type
            {6} = other reward type.
            {7} = mission description
            {8} = credit amount.
    ###
    extraReward: "<table id=\"alerts-table-{0}\" cellspacing=\"0\" cellpadding=\"3\">
    <tr>
        <td colspan=\"2\" class=\"time-left\"><span{1}>{2}</span></td>
    </tr>
    <tr>
        <td class=\"location\">{3} - <em>{4} {5}</em></td>
        <td class=\"other-reward\">
            <span>{6}</span>
        </td>
    </tr>
    <tr>
        <td><em>{7}</em></td>
        <td class=\"credit-reward\">{8}</td>
    </tr>
</table>"
    
    noAlerts: "<table id=\"alerts-table-0\" cellspacing=\"0\" cellpadding=\"3\">
    <tr>
        <td style=\"text-align: center;\"><em>No alerts at this time.</em></td>
    </tr>
</table>"
}

$( document ).ready ->
    chrome.browserAction.setBadgeText { text: "" }
    
    value = 0
    
    $( "#alerts-expander" ).rotate {
        bind: {
            click: ->
                if value is 180
                    value = 0
                else if value is 0
                    value = 180
                else
                    value = 0
                
                $( this ).rotate { animateTo: value, duration: 1250 }
                
                slideOpts = {
                    duration: 500,
                    queue: ( no )
                }
                
                if value is 0
                    $( "#alerts-container" ).slideDown( slideOpts );
                else
                    $( "#alerts-container" ).slideUp( slideOpts );
        }
    }
    
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
                
                if diff <= 0
                    console.log "Old alert ({0}). Expires: {1} ({2}); Now: {3} ({4}).".format k, v.expireTime, new Date( v.expireTime * 1000 ), now(), new Date( now() * 1000 )
                    continue
                else
                    console.log "Expires: {1} ({2}); Now: {3} ({4}).".format v.expireTime, new Date( v.expireTime ), now(), new Date( now() * 1000 )
                    
                isUrgent = diff <= 60
                range = "Lv. {0}-{1}".format v.levelRange.low, v.levelRange.high
                where = "{0} ({1})".format v.node, v.planet
                
                if v.rewards.extra.length > 0
                    inner += htmlFormat.extraReward.format( k, ( if isUrgent then " class=\"urgent\"" else "" ), timeSpan( diff ), where, range, v.type, v.rewards.extra[0], v.message, v.rewards.credits ) 
                else
                    inner += htmlFormat.creditOnly.format( k, ( if isUrgent then " class=\"urgent\"" else "" ), timeSpan( diff ), where, range, v.type, v.message, v.rewards.credits ) 
            catch e
                console.log e.stack.toString()

        console.log( if inner is "" then "<Empty>" else inner )
        
        if inner is ""
            inner = htmlFormat.noAlerts
            
        $( "#alerts-container" ).html inner
        return
    return