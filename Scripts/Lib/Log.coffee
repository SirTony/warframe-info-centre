Log = new (
    class
        Debug: ( args... ) ->
            console.debug args... if App.Debug

        Trace: ( args... ) ->
            console.trace args... if App.Trace

        Write: ( args... ) ->
            console.log args...   if App.Verbose

        Info: ( args... ) ->
            console.info args...  if App.Verbose

        Warn: ( args... ) ->
            console.warn args...

        Error: ( args... ) ->
            console.error args...
)