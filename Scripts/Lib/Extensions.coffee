isUndefined = ( x ) -> typeof x is "undefined"
isString    = ( x ) -> typeof x is "string"
isObject    = ( x ) -> typeof x is "object"
isFunction  = ( x ) -> typeof x is "function"
isNumber    = ( x ) -> typeof x is "number"
isUndefined = ( x ) -> typeof x is "undefined"
isBoolean   = ( x ) -> typeof x is "boolean"

now = -> Math.floor new Date().getTime() / 1000
Math.randInt = ( max ) -> Math.floor Math.random() * max

String.random = ( len = 5, chars = "abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ".split "" ) ->
    str = [ ]
    str.push chars.sample() for _ in [ 0 ... len ]

    return str.join ""

Array::sample = ->
    index = Math.randInt @.length - 1
    return @[index]

Array::equals = ( other ) ->
    if this is other then return yes
    if this is null or other is null then return no
    if this.length isnt other.length then return no

    for i in [0 ... this.length] by 1
        if this[i] isnt other[i] then return no

    return yes

except = ( fn ) ->
    try
        fn?()
    catch e
        Log.Error if e.getMessage? then e.getMessage() else e.toString()
        Log.Trace e

Function::property = ( prop, fn, isStatic = no ) ->
    target = if isStatic then @ else @::
    Object.defineProperty target, prop, fn

Array::all = ( fn ) ->
    if not isFunction fn
        throw new ArgumentException "Array.all expects parameter 1 to be a function, {0} given.".format( typeof predicate )
    
    for v in @
        if not fn v
            return no
    
    return yes

Number::between = ( lo, hi, inclusive = yes ) ->
    if not isNumber lo
        throw new ArgumentException "Number.between expects parameter 1 to be a number, {0} given.".format( typeof lo )
    
    if not isNumber hi
        throw new ArgumentException "Number.between expects parameter 2 to be a number, {0} given.".format( typeof hi )
    
    return if inclusive is yes then @ >= lo and @ <= hi else @ > lo and @ < hi

String::format = ( args... ) ->
    if args.length is 0
        return @
    
    formatted = @.replace /(\{)?\{(\d+)\}(?!\})/g, ( $0, $1 ) =>
        return $0 if $1?

        index = $0.replace /(?:\{|\})/g, ""
        val   = args[index].toString?() if args[index]?

        return val if val?
        return ""

    return formatted.replace( "{{", "{" ).replace "}}", "}"

timeSpan = ( secs ) ->
    if not isNumber secs
        throw new ArgumentException "timeSpan expects parameter 1 to be a number, {0} given.", typeof secs
    
    if secs < 60
        return "{0}s".format secs
    
    mins = Math.floor secs / 60
    
    if mins < 60
        return "{0}m {1}s".format( mins, secs % 60 )
    
    hours = Math.floor mins / 60
    
    if hours < 24
        return "{0}h {1}m {2}s".format( hours, mins % 60, secs % 60 )
    
    #Days
    return "{0}d {1}h {2}m {3}s".format( Math.floor( hours / 24 ), hours % 24, mins % 60, secs % 60 )

owns = ( self, prop ) -> self.hasOwnProperty prop

selectKeys = ( self, keys... ) ->
    newObject = { }
    
    for k, v of self
        if k in keys
            newObject[k] = v
    
    return newObject

values = ( self, stripFunctions = true ) ->
    ret = [ ]
    
    for k, v of self
        if stripFunctions and isFunction v
            continue
        else if owns self, k
            ret.push v
    
    return ret
 
keys = ( self ) ->
    ret = [ ]
    
    for k, v of self
        if owns self, k
            ret.push k
        else
            continue
    
    return ret