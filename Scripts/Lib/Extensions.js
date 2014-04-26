function isString   ( x ) { return typeof x === "string"   ; }
function isObject   ( x ) { return typeof x === "object"   ; }
function isFunction ( x ) { return typeof x === "function" ; }
function isNumber   ( x ) { return typeof x === "number"   ; }
function isUndefined( x ) { return typeof x === "undefined"; }

function now() { return new Date().getTime(); }

Object.prototype.values = function() {
    values = [ ];
    
    for( key in this )
        if( this.hasOwnProperty( key ) )
            values.push( this[key] );
    
    return values;
};

Array.prototype.map = function( callback ) {
    if( !isFunction( callback ) )
        throw "Array.map expects parameter 1 to be a function, {0} given.".format( typeof callback );
        
    var newArray = [ ];
    
    for( var i = 0; i < this.length; ++i )
        newArray.push( callback( this[i] ) );
    
    return newArray;
};

Array.prototype.filter = function( predicate ) {
    if( !isFunction( predicate ) )
        throw "Array.filter expects parameter 1 to be a function, {0} given.".format( typeof predicate );
        
    var filtered = [ ];
    
    for( var i = 0; i < this.length; ++i )
        if( predicate( this[i] ) === true )
            filtered.push( this[i] );
    
    return filtered;
};

Array.prototype.all = function( predicate ) {
    if( !isFunction( predicate ) )
        throw "Array.filter expects parameter 1 to be a function, {0} given.".format( typeof predicate );
    
    for( var i = 0; i < this.length; ++i )
        if( predicate( this[i] ) !== true )
            return false;
    
    return true;
};

Number.prototype.between = function( lo, hi, inclusive ) {
    if( !isNumber( lo ) )
        throw "Number.between expects parameter 1 to be a number, {0} given.".format( typeof lo );
    
    if( !isNumber( hi ) )
        throw "Number.between expects parameter 2 to be a number, {0} given.".format( typeof hi );
    
    if( isUndefined( inclusive ) )
        inclusive = true;
        
    return inclusive === true ? this >= lo && this <= hi : this > lo && this < hi;
};

String.prototype.format = function() {
    if( this === null || isUndefined( this ) || !( this instanceof String ) )
        throw "String.format expects parameter 1 to be a string, '" + ( typeof this ) + "' given.";
        
    if( arguments.length === 0 )
        return this;
    
    var formatters = this.match( /(\{\d+\})/g ).map( function( x ) { return parseInt( x.slice( 1, -1 ) ); } ).sort( function( a, b ) { return b - a; } );
    
    if( formatters.length === 0 )
        return this;
    
    var formatted = this;
    for( i = 0; i < formatters.length; ++i )
        formatted = formatted.replace( "{" + formatters[i].toString() + "}", arguments[formatters[i]].toString() );
    
    return formatted;
};