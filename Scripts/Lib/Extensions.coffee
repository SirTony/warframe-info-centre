isString    = ( x ) -> typeof x is "string"
isObject    = ( x ) -> typeof x is "object"
isFunction  = ( x ) -> typeof x is "function"
isNumber    = ( x ) -> typeof x is "number"
isUndefined = ( x ) -> typeof x is "undefined"
isBoolean   = ( x ) -> typeof x is "boolean"

now = -> new Date().getTime()

Object.prototype.values = ( stripFunctions = true ) ->
	ret = [ ]
	
	for k, v of @
		if stripFunctions and isFunction v
			continue
		else if @.hasOwnProperty k
			ret.push v
	
	return ret

Object.prototype.keys = ->
	ret = [ ]
	
	for k, v of @
		if @.hasOwnProperty k
			ret.push k
		else
			continue
	
	return ret

Array.prototype.map = ( fn ) ->
	if not isFunction fn
		throw new ArgumentException "Array.map expects parameter 1 to be a function, {0} given.".format( typeof fn )
	
	mapped = [ ]
	
	for v in @
		mapped.push fn v
	
	return mapped

Array.prototype.filter = ( fn ) ->
	if not isFunction fn
		throw new ArgumentException "Array.filter expects parameter 1 to be a function, {0} given.".format( typeof predicate )
	
	filtered = [ ]
	
	for v in @
		if fn( v ) is ( true )
			filtered.push v
	
	return filtered

Array.prototype.all = ( fn ) ->
	if not isFunction fn
		throw new ArgumentException "Array.filter expects parameter 1 to be a function, {0} given.".format( typeof predicate )
	
	for v in @
		if not fn v
			return no;
	
	return yes;

Number.prototype.between = ( lo, hi, inclusive = yes ) ->
	if not isNumber lo
		throw new ArgumentException "Number.between expects parameter 1 to be a number, {0} given.".format( typeof lo )
	
	if not isNumber hi
		throw new ArgumentException "Number.between expects parameter 2 to be a number, {0} given.".format( typeof hi )
	
	return if inclusive is yes then @ >= lo and @ <= hi else @ > lo and @ < hi

String.prototype.format = ->
	if arguments.length is 0
		return @
	
	formatters = @.match( /(\{\d+\})/g )
	
	if formatters.length is  0
		return @
	
	formatted = @
	
	for i in [ 0 .. formatters.length ]
		formatted = formatted.replace "{" + formatters[i].toString() + "}", arguments[formatters[i]].toString()
	
	return formatted