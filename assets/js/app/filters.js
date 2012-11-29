/* http://docs.angularjs.org/#!angular.filter */

function convertDateToUTC(date) {
	if (!date) return date
	return new Date(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate(),
			date.getUTCHours(), date.getUTCMinutes(), date.getUTCSeconds(),
			date.getUTCMilliseconds())
}

var myModule = angular.module('myModule', []);


myModule.filter('boolean', function(input) {
	return input ? 'true' : 'false';
});

myModule.filter('percent', function(input) {
	return parseFloat(input || 0).toFixed(2)+'%';
});

/*
angular.formatter('countrycode', {
	parse: function(value){
		return (value||'').toUpperCase();
	},
	format: function(value){
		return value;
	}
});
*/

myModule.filter('won', function(flag) { return flag ? '✓' : '&mdash;' })

function dateDiff(startDate, endDate) {
	function getWholeDays(date) { return Math.floor(date / (1000*60*60*24)) }
	return getWholeDays(endDate) - getWholeDays(startDate)
}

myModule.filter('dyndate', function(date) {
	var now = new Date()
	var diff = dateDiff(date, now)
	if (diff == 0) { // "8:44 PM" for today
		return myModule.filter.date.call(this, date, 'h:mm a')
	} else if (diff == 1) { // "yesterday at 8:44 PM" for yesterday
		return 'yesterday at '+myModule.filter.date.call(this, date, 'h:mm a')
	// } else if (diff > 1 && diff <= 7) { // "5 days ago" within 1 week
	// 	return diff+' days ago at '+angular.filter.date.call(this, date, 'h:mm a')
	} else { // "Nov 6" else
		return myModule.filter.date.call(this, date, 'MMM d')
	}
})

/*
angular.formatter('datetime', {
	parse: function(value){
		value = value.replace(' ', 'T')
		if (value.length == 10) value += '00:00:00'
		if (value.indexOf('.') < 0) value += '.000Z'
		var s = angular.fromJson('"'+value+'"')
		if (s && typeof(s) == 'object') {
			// convert to UTC, because the user entered the date in their local timezone
			s = convertDateToUTC(s)
		}
		return s
	},
	format: function(value){
		return myModule.filter.date.call(this, value, 'yyyy-MM-dd HH:mm:ss')
	}
})
*/

myModule.filter('ml', function(s) { return myModule.filter.html.call(this, s.replace(/\n/g, '<br/>')) })
