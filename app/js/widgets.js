/* http://docs.angularjs.org/#!angular.widget */

//automatically resize the textarea's height according to the content
//http://james.padolsey.com/javascript/jquery-plugin-autoresize/
angular.widget('@ng:autoresize', function(expression, template) {
	var bindExpr = template.attr('name')

 	return function(linkElement) {
 		linkElement = $(linkElement)
		if (bindExpr) {
			var scope = this
			//set the initial value to the textarea
			linkElement.text(scope.$eval(bindExpr))
			//watch for the model's changes for 2 way data binding
			scope.$watch(bindExpr, function(scope, newValue, oldValue){
				linkElement.text(newValue)
			})
			//set the model value in the angular scope when the text changed in the textarea
			linkElement
				.unbind('.autoresize')
				.bind('keyup.autoresize keydown.autoresize change.autoresize input.autoresize paste.autoresize', function(){
					s = this.value || ''
					//sanitize the entered text to prevent syntax errors in the assembled expression
					s = s.replace(/\\/g, '\\\\').replace(/"/g, '\\"')
					//do the assignment with $apply. the expression is like ''' x = "string" '''
					scope.$apply(bindExpr + ' = "' + s + '"')
				})
		}
		linkElement.autoResize({
			extraSpace : 10
		})
		linkElement.keyup() //initialize the textarea's height
	}
})
