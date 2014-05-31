isString    = ( x ) -> typeof x is "string"
isObject    = ( x ) -> typeof x is "object"
isFunction  = ( x ) -> typeof x is "function"
isNumber    = ( x ) -> typeof x is "number"
isUndefined = ( x ) -> typeof x is "undefined"
isBoolean   = ( x ) -> typeof x is "boolean"

now = -> Math.floor new Date().getTime() / 1000

Function::property = ( prop, fn, isStatic = no ) ->
    target = if isStatic then self else self::
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

String::format = ->
    if arguments.length is 0
        return @
    
    formatters = @.match( /(\{\d+\})/g )
    
    if( formatters is null or formatters.length is 0 )
        return @

    if formatters.length is 1
        return @.replace "{0}", arguments[0].toString()
    
    formatted = @
    for i in [ 0 .. formatters.length - 1 ]
        j = parseInt( formatters[i].replace( "{", "" ).replace( "}", "" ) )
        _v = if not isUndefined( arguments[j] ) and not isUndefined( arguments[j].toString ) then arguments[j].toString() else arguments[j]
        formatted = formatted.replace formatters[i], _v
    
    return formatted

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

selectKeys = ->
    if arguments.length is 1
        return arguments[0]
    
    self = arguments[0]
    newObject = { }
    args = values( arguments ).slice 1
    
    for k, v of self
        if k in args
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