isString    = ( x ) -> typeof x is "string"
isObject    = ( x ) -> typeof x is "object"
isFunction  = ( x ) -> typeof x is "function"
isNumber    = ( x ) -> typeof x is "number"
isUndefined = ( x ) -> typeof x is "undefined"
isBoolean   = ( x ) -> typeof x is "boolean"

now = -> new Date().getTime()

httpGet = ( url, success ) ->
	if not isString url
		throw new ArgumentException "httpGet expects parameter 1 to be a string, {0} given.".format( typeof url )
	
	if not isFunction success
		throw new ArgumentException "httpGet expects parameter 2 to be a function, {0} given.".format( typeof success )
	
	xmlHttp = new XMLHttpRequest()
	xmlHttp.onreadystatechange = ->
		if xmlHttp.readyState is 4 and xmlHttp.status is 200
			success xmlHttp.responseText
	
	xmlHttp.open "GET", url, yes;
	xmlHttp.send null;

Object.prototype.selectKeys = ->
	if arguments.length is 0
		return @
	
	newObject = { }
	args = arguments.values()
	
	for k, v of @
		if k in args
			newObject[k] = v
	
	return newObject

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

	#If the regex above only matches one thing, we get a string instead of an array.
	if formatters.length is 1
		return @.replace "{0}", arguments[0].toString()
		
	formatted = 0
	for i in [ 0 .. formatters.length ]
		formatted = formatted.replace "{" + formatters[i].toString() + "}", arguments[i].toString()
	
	return formatted