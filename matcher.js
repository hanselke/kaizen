
oagis = require('./oagis')
assert = require('assert')

exports.matcher = matcher
exports.init = function(Object) {
	if (undefined != Object.match) return;
	Object.defineProperty(Object.prototype, "match", {
		enumerable: false,
		value: function(obj) { return exports.matcher(this, obj) }
	});
	Object.defineProperty(Object.prototype, "matcher", {
		enumerable: false,
		value: function(obj) {
			//returns the value of the first match
			var res = exports.matcher(this, obj)
			if (res && res.length == 1) return res[0][1]
			return res
		}
	})
}

function matcher(obj, exp){
	var arr = exp.split('/')
	var str = ''
	for (var i in arr) {
		var s = arr[i]
		if (!s) {
			str += '.*'
			continue
		}
		if (str) str += '/[^/]*'
		if (s.substr(0, 1) == "'") {
			str += '\\b'+s.substr(1)+'\\b'
		} else {
			var chars = s.split('')
			str += '[^/]*'+chars.join('[^/]*')+'[^/]*'
		}
	}
//	console.log(exp+' => '+str)
	var regex = new RegExp(str)
	return rmatcher(obj, regex)
}
function rmatcher(obj, regex, prefix){
	if (!prefix) prefix = ''

	var results = []
	var keys = Object.keys(obj)
	for (var i in keys) {
		var key = keys[i]
		var value = obj[key]
		if (regex.test(prefix + key)) {
			results.push([prefix + key, value])
		} else if (value && typeof(value) == 'object') {
			results = results.concat(rmatcher(value, regex, prefix + key + '/'))
		}
	}
	return results
}

function test(){
	assert.deepEqual(matcher({a: 1}, 'a'), [['a', 1]])
	assert.deepEqual(matcher({ab: 1}, 'a'), [['ab', 1]])
	assert.deepEqual(matcher({a: {b: 2}}, 'a/b'), [['a/b', 2]])
	assert.deepEqual(matcher({a: {b: 2}}, 'ab'), [])
	assert.deepEqual(matcher({ab: {b: 2}}, 'a/b'), [['ab/b', 2]])
	assert.deepEqual(matcher({ab: {b: 2, bb: 3}}, 'a/b'), [['ab/b', 2], ['ab/bb', 3]])
	assert.deepEqual(matcher({ab: {b: 2, bb: 3}}, 'a/bb'), [['ab/bb', 3]])
	assert.deepEqual(matcher({ab: {b: 2}}, '\'a/b'), [])
	assert.deepEqual(matcher({ab: {b: 2}}, 'b'), [['ab', {b: 2}]])
	assert.deepEqual(matcher({ab: {b: 2}}, '\'b'), [['ab/b', 2]])
	assert.deepEqual(matcher({ab: {b: 2}}, 'A/b'), [])
	assert.deepEqual(matcher({ab: {b: 2, c: {d: 3}}}, 'a//d'), [['ab/c/d', 3]])
	assert.deepEqual(matcher({ab: {b: 2, c: {d: 3}}}, 'd'), [['ab/c/d', 3]])

	assert.deepEqual(matcher({ab: [{b: 2}, {c: {d: 3}}]}, 'a/1//d'), [['ab/1/c/d', 3]])
	assert.deepEqual(matcher({ab: [{b: 2}, {c: {d: 3}}]}, 'a/0/d'), [])
	assert.deepEqual(matcher({ab: [{b: 2}, {c: {d: 3}}]}, 'd'), [['ab/1/c/d', 3]])

	assert.deepEqual(matcher(oagis.ProcessRFQ, "RFQ/Head/Ref/'DocumentID/'ID"), [['DataArea/RFQ/RFQHeader/DocumentReference/DocumentID/ID', null]])
	assert.deepEqual(matcher(oagis.ProcessRFQ, "RFQ/Head/'DocumentID/'ID"), [['DataArea/RFQ/RFQHeader/DocumentID/ID', null]])
}

test()

