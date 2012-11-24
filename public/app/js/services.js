/* http://docs.angularjs.org/#!angular.service */

/**
 * App service which is responsible for the main configuration of the app.
 */
angular.service('myAngularApp', function($route) {
	// controller.js redirects to #/signin if current_user is 404
	$route.when('/',  {template: 'main.html', controller: MainController})
	$route.when('/register',  {template: 'register.html', controller: RegisterController})
	$route.when('/signin',  {template: 'signin.html', controller: SigninController})
	$route.when('/sales-rfq',  {template: 'sales-rfq.html', controller: SalesRFQController})
	$route.when('/sales-quote',  {template: 'sales-quote.html', controller: SalesQuoteController})
	$route.when('/purchasing-rfq',  {template: 'purchasing-rfq.html', controller: PurchasingRFQController})
	$route.when('/backoffice-sales-rfq',  {template: 'backoffice-sales-rfq.html', controller: BackofficeSalesRFQController})
	$route.when('/backoffice-supplier-rfq',  {template: 'backoffice-supplier-rfq.html', controller: BackofficeSupplierRFQController})
	$route.when('/backoffice-sales-quote',  {template: 'backoffice-sales-quote.html', controller: BackofficeSalesQuoteController})
	$route.when('/backoffice-customer-quote',  {template: 'backoffice-customer-quote.html', controller: BackofficeCustomerQuoteController})
	$route.when('/board',  {template: '', controller: BoardController})
	$route.when('/board-examples',  {template: 'board-examples.html', controller: BoardExamplesController})
	$route.when('/print-quote',  {template: 'print-quote.html', controller: PrintQuoteController})
	$route.when('/print-rfq',  {template: 'print-rfq.html', controller: PrintRFQController})

	$route.when('/backoffice-sales-po',  {template: 'backoffice-sales-po.html', controller: BackofficeSalesPOController})
	$route.otherwise({redirectTo: '/'})
}, {$inject:['$route'], $eager: true});
