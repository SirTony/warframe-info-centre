class Notification
    active = [ ]
    options = { }

    constructor: ( header, body, icon ) ->
        options = { }
        options.title   = header ? ""
        options.message = body   ? ""
        options.iconUrl = icon   ? chrome.extension.getURL "/Icons/Warframe.Notification.Large.png"

    getTitle: -> options.title
    setTitle: ( value ) -> options.title = value

    getMessage: -> options.message
    setMessage: ( value ) -> options.message = value

    getIcon: -> options.iconUrl
    setIcon: ( url ) -> options.iconUrl = url

    getType: -> checkType()
    setType: ( value ) -> options.type = value

    addItem: ( object ) ->
        if not options.items?
            options.items = [ ]

        options.items.push object

    addItems: ( objects... ) ->
        for object in objects
            @.addItem object

    clearItems: -> delete options.items
    getItems:   -> options.items ? [ ] 

    show: ( timeout, fn ) ->
        checkType()
        id = String.random 64

        while id in active #let's just be double sure there are no duplicates
            id = String.random 64

        chrome.notifications.create id, options, ( s ) =>
            active.push s

            if timeout? and isNumber( timeout ) and timeout > 0
                setTimeout ( =>
                    if id in active
                        chrome.notifications.clear id, =>
                            delete active[active.indexOf id]
                ), timeout * 1000

            fn? s

    checkType = ->
        if not options.type?
            options.type = if options.items? then "list" else "basic"

        return options.type