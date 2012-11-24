var	fs = require('fs'),
	k = require('kyuri');

feature = fs.readFileSync('/usr/local/lib/node_modules/kyuri/examples/complex.feature', encoding = 'ascii');

ast = k.parse('Feature: Addition \n\
	In order to avoid silly mistakes	 \n\
	As a math idiot 	 \n\
	I want to be told the sum of two numbers  \n\
\n\
	@tag1 @tag2  \n\
#AND A COMMENT!!!  \n\
	Scenario: Add two numbers  \n\
		Given I have entered 50 into the calculator \n\
		And I have entered 70 into the calculator \n\
		When I press add \n\
		Then the result should be 120 on the screen\n\
');
ast = k.parse(feature);
// console.log(ast);
compiled = k.compile(ast, { directory: './features/', target: 'all' });
console.log(compiled.vows[0].text);
console.log(compiled.steps[0].text);
// console.log(JSON.stringify(k.runners.vows.createVows('addition.feature', ast).batches[0].tests, null, '  '));
// k.runners.vows.createVows('addition.feature', ast);
