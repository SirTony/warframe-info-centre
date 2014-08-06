Message = new (
    class
        callbacks = { }

        constructor: ->
            if window is chrome.extension.getBackgroundPage() #We only hook onMessage in the background page.
                chrome.runtime.onMessage.addListener handler

        on: ( actionName, fn ) ->
            if actionName not in keys callbacks
                callbacks[actionName] = fn

        send: ( action, data = { } ) ->
            data.action = action
            chrome.runtime.sendMessage data, =>

        handler = ( message, sender ) ->
            if sender isnt chrome.runtime.id and not App.Debug
                return

            if not message?.action? #?!?!???!?!?
                return

            Log.Info "New message with action ", message.action
            if message.action not in keys callbacks
                return
            else
                callbacks[message.action]?( message )
)