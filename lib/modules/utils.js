// Usage:
//   require('utils.js').init(Object)
//
// Sources:
// http://stackoverflow.com/questions/122102/what-is-the-most-efficient-way-to-clone-a-javascript-object
// http://stackoverflow.com/questions/2256040/javascript-extends-class
// extend() function:  http://stackoverflow.com/questions/5055746/cloning-an-object-in-node-js
// clone() function:  http://oranlooney.com/functional-javascript/  (from a comment)

//from jQuery 1.4.2
exports.extend = function() {
	// copy reference to target object
	var target = arguments[0] || {}, i = 1, length = arguments.length, deep = false, options, name, src, copy;

	// Handle a deep copy situation
	if ( typeof target === "boolean" ) {
		deep = target;
		target = arguments[1] || {};
		// skip the boolean and the target
		i = 2;
	}

	// Handle case when target is a string or something (possible in deep copy)
	if ( typeof target !== "object" && !isFunction(target) ) {
		target = {};
	}

	// extend jQuery itself if only one argument is passed
	if ( length === i ) {
		target = this;
		--i;
	}

	for ( ; i < length; i++ ) {
		// Only deal with non-null/undefined values
		if ( (options = arguments[ i ]) != null ) {
			// Extend the base object
			for ( name in options ) {
				src = target[ name ];
				copy = options[ name ];

				// Prevent never-ending loop
				if ( target === copy ) {
					continue;
				}

				// Recurse if we're merging object literal values or arrays
				if ( deep && copy && ( isPlainObject(copy) || isArray(copy) ) ) {
					var clone = src && ( isPlainObject(src) || isArray(src) ) ? src
						: isArray(copy) ? [] : {};

					// Never move original objects, clone them
					target[ name ] = exports.extend( deep, clone, copy );

				// Don't bring in undefined values
				} else if ( copy !== undefined ) {
					target[ name ] = copy;
				}
			}
		}
	}

	// Return the modified object
	return target;
}

exports.init = function(Object) {
	if (undefined != Object.extend) return;
	Object.defineProperty(Object.prototype, "extend", {
		enumerable: false,
		value: function(obj) { return exports.extend.call(this, true, obj) }
	});

	Object.defineProperty(Object.prototype, "flatExtend", {
		enumerable: false,
		value: function(obj) { return exports.extend.call(this, false, obj) }
	});

	Object.defineProperty(Object.prototype, "deepCopy", {
		enumerable: false,
		value: function() { return JSON.parse(JSON.stringify(this)); }
	});
}
function isFunction( obj ) { return toString.call(obj) === "[object Function]" }
function isArray( obj ) { return toString.call(obj) === "[object Array]" }
function isPlainObject( obj ) {
	// Must be an Object.
	// Because of IE, we also have to check the presence of the constructor property.
	// Make sure that DOM nodes and window objects don't pass through, as well
	if ( !obj || toString.call(obj) !== "[object Object]" || obj.nodeType || obj.setInterval ) {
		return false;
	}

	// Not own constructor property must be Object
	if ( obj.constructor
		&& !hasOwnProperty.call(obj, "constructor")
		&& !hasOwnProperty.call(obj.constructor.prototype, "isPrototypeOf") ) {
		return false;
	}

	// Own properties are enumerated firstly, so to speed up,
	// if last one is own, then all properties are own.

	var key;
	for ( key in obj ) {}

	return key === undefined || hasOwnProperty.call( obj, key );
}

/** Generates an rfc4122 version 4 compliant UUID.
* From http://stackoverflow.com/questions/105034/how-to-create-a-guid-uuid-in-javascript */
exports.generateUUID = function() {
	return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
		var r = Math.random()*16|0, v = (c == 'x' ? r : (r&0x3|0x8));
		return v.toString(16);
	});
}
