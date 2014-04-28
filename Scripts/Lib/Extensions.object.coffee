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