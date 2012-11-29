/* http://docs.angularjs.org/#!angular.service */

/**
 * App service which is responsible for the main configuration of the app.
 */
angular.service('myAngularApp', function($route) {
	// controller.js redirects to #/signin if current_user is 404
	$route.when('/',  {template: 'main', controller: MainController})
	$route.when('/register',  {template: 'register', controller: RegisterController})
	$route.when('/signin',  {template: 'signin', controller: SigninController})
	$route.when('/sales-rfq',  {template: 'sales-rfq', controller: SalesRFQController})
	$route.when('/sales-quote',  {template: 'sales-quote', controller: SalesQuoteController})
	$route.when('/purchasing-rfq',  {template: 'purchasing-rfq', controller: PurchasingRFQController})
	$route.when('/backoffice-sales-rfq',  {template: 'backoffice-sales-rfq', controller: BackofficeSalesRFQController})
	$route.when('/backoffice-supplier-rfq',  {template: 'backoffice-supplier-rfq', controller: BackofficeSupplierRFQController})
	$route.when('/backoffice-sales-quote',  {template: 'backoffice-sales-quote', controller: BackofficeSalesQuoteController})
	$route.when('/backoffice-customer-quote',  {template: 'backoffice-customer-quote', controller: BackofficeCustomerQuoteController})
	$route.when('/board',  {template: '', controller: BoardController})
	$route.when('/board-examples',  {template: 'board-examples', controller: BoardExamplesController})
	$route.when('/print-quote',  {template: 'print-quote', controller: PrintQuoteController})
	$route.when('/print-rfq',  {template: 'print-rfq', controller: PrintRFQController})
	$route.when('/task',  {template: 'task', controller: TaskController})

	$route.when('/backoffice-sales-po',  {template: 'backoffice-sales-po', controller: BackofficeSalesPOController})
	$route.otherwise({redirectTo: '/'})
}, {$inject:['$route'], $eager: true});
