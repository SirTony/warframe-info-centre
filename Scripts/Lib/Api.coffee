class Api
    __platform = "PC"

    urls =
    Alerts:
        PC:  "http://deathsnacks.com/wf/data/alerts_raw.txt"
        PS4: "http://deathsnacks.com/wf/data/ps4/alerts_raw.txt",
    Invasions:
        PC:  "http://deathsnacks.com/wf/data/invasion_raw.txt",
        PS4: "http://deathsnacks.com/wf/data/ps4/invasion_raw.txt"

    httpGet = ( url, success ) ->
        if not isString url
            throw new ArgumentException "httpGet expects parameter 1 to be a string, {0} given.".format( typeof url )

        if not isFunction success
            throw new ArgumentException "httpGet expects parameter 2 to be a function, {0} given.".format( typeof success )

        xmlHttp = new XMLHttpRequest()
        xmlHttp.onreadystatechange = ->
            if xmlHttp.readyState is 4 and xmlHttp.status is 200
                success xmlHttp.responseText

        xmlHttp.open "GET", url, yes
        xmlHttp.send null

    @property "platform",
    get: -> __platform
    set: ( newPlatform ) ->
        if not isString newPlatform
            throw new ArgumentException "platform only accepts string values, {0} given.".format typeof newPlatform

        __platform = newPlatform
        return
    , yes

    @getAlerts: ( fn ) ->
        if not isFunction fn
            throw new ArgumentException "getAlerts expects parameter 1 to be a function, {0} given.".format typeof fn

        httpGet urls.Alerts[__platform], ( text ) ->
            lines = text.split "\n"

            if lines.length < 2
                return

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

            fn alerts
            return
        return

    @getInvasions: ( fn ) ->
        if not isFunction fn
            throw new ArgumentException "getInvasions expecta parameter 1 to be a function, {0} given.".format typeof fn

        httpGet urls.Invasions[__platform], ( text ) ->
            lines = text.split "\n"

            if lines.length < 2
                return

            invasions = { }

            for line in lines
                parts = line.split "|"

                if parts.length < 19
                    continue

                range1 = parts[6].split "-"
                range2 = parts[11].split "-"

                obj = {
                    planet: parts[2],
                    node: parts[1],
                    factions: {
                        contestant: {
                            name: parts[3],
                            missionType: parts[4],
                            reward: if parts[3] is "Infestation" then null else parts[5],
                            levelRange: {
                                low: parseInt( range1[0] ),
                                high: parseInt( range1[1] )
                            },
                            squad: parts[7] #This is included for complete-ness, we don't actually need it.
                        },
                        controlling: {
                            name: parts[8],
                            missionType: parts[9],
                            reward: if parts[8] is "Infestation" then null else parts[10],
                            levelRange: {
                                low: parseInt( range2[0] ),
                                high: parseInt( range2[1] )
                            },
                            squad: parts[12] #ditto
                        }
                    },
                    startTime: parseInt( parts[13] ),
                    score: {
                        current: parseInt( parts[14] ),
                        goal: parseInt( parts[15] ),
                        percent: parseFloat( parts[16] )
                    },
                    eta: parts[17],
                    message: parts[18]
                }

                invasions[parts[0]] = obj

            fn invasions
            return
        return