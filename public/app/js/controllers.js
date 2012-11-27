if (parent && parent.window && parent.window.angular && parent.window.angular.scenario) {
	(function(){
		window.alert = function(msg) {
			console.log('ALERT:',msg);
		}
	})();
}
AppController.$inject = ['$resource', '$route', '$location', '$xhr', '$defer', '$window'];
function AppController($resource, $route, $location, $xhr, $defer, $window){
	$route.parent(this);
	this.$route = $route;
	this.$location = $location;
	this.$xhr = $xhr;
	this.$defer = $defer;
	this.$window = $window
	this.$xhr.defaults.headers.post['Content-Type']='application/json';

	this.getset = function(var_name, getter, setter) {
		this.__defineGetter__(var_name, getter)
		this.__defineSetter__(var_name, setter)
	}

	this.COUNTRY_CODES = COUNTRY_CODES;

	//the HTTP actions used by the application. verifyCache=true is needed to
	//prevent caching by angular
	var actions = {
		'get':    {method:'GET', verifyCache: true},
		'save':   {method:'POST'},
		'query':  {method:'GET', isArray:true, verifyCache: true},
		'remove': {method:'DELETE'},
		'delete': {method:'DELETE'}
	}
	this.Registration = $resource('/users/:id', {id: '@id'}, actions);
	this.Login = $resource('/login', {}, actions);

	this.results = [];
	// this.currentUser can have 3 possible values:
	// - undefined: didn't receive the response for GET /api/session, so we
	//      don't know if there is a signed in user or not
	// - null: there is no signed in user
	// - an object: the signed in user's properties
	this.currentUser = undefined;
	this.loadCurrentUser();
	var flash = ''
	this.getset('flash',
		function() {var current_flash = flash; flash = ''; return current_flash},
		function(new_flash) {flash = new_flash})

	this.roles = ['fax', 'customer', 'backoffice', 'sales', 'purchasing', 'admin']
	var chat_lines = []
	this.getset('chat_lines',
		function() {return chat_lines},
		function(new_chat_lines) {chat_lines = new_chat_lines})
	this.chat_socket = io.connect('/')
	var that = this
	this.chat_socket.on('connect', function(){
		if (that.currentUser) {
			that.chat_socket.emit('nick', {nick: that.currentUser.name})
			that.$digest()
		}
	})
}
AppController.prototype = {
	log: function(data){
		if (console && typeof(console.log) == 'function') { console.log(data) }
		return data;
	},
	objectValues: function(obj){
		var arr = []
		for (var k in obj) arr.push(obj[k])
		return arr
	},
	getItem: function(name, defaultValue){
		if (localStorage && (typeof(localStorage.getItem) == 'function') && (name in localStorage)) {
			return localStorage.getItem(name)
		}
		return defaultValue
	},
	setItem: function(name, value){
		if (localStorage && typeof(localStorage.setItem) == 'function') {
			localStorage.setItem(name, value)
		}
	},
	setRole: function(role){ var that = this
		this.$xhr('POST', '/set_role', {role: role}, function(code, response) {
			that.setCurrentUser(response);
		}, that.errorHandler);
	},
	getRoleClass: function(role) { return (this.currentUser && this.currentUser.roles.indexOf(role) >= 0) ? 'on' : '' },
	errorHandler: function(code, error) {
		var field	// backend can send back a field name so it can be focused
		if (typeof(error) == 'object') { field = error.field; error = error.msg }
		if (!error) { error = code+': Unknown error!' }
		this.$window.alert(error);
		if (code == 401) { // Unauthorized => show signin form
			this.currentUser = undefined
		}
		if (field) this.$defer(function(){ $('input[name="'+field+'"]').focus().select() })
	},
	isUserSignedIn: function() {
		return this.currentUser && this.currentUser.email ? true : false; //need to return false explicitly
	},
	loadCurrentUser: function() { var that = this
		this.$xhr('GET', '/api/session',
			function(code, res) { that.setCurrentUser(res)},
			// avoid calling error handler if the only problem is the lack of logged in user
			function(code, res){ that.setCurrentUser(null)
				if (code != 404) that.errorHandler(code, res)
				else that.$location.path('signin')})
	},
	setCurrentUser: function(user) {
		this.currentUser = user;
		if (user && user.name) this.chat_socket.emit('nick', {nick: user.name})
	},
	signout: function() { var that = this
		if (!this.isUserSignedIn()) return
		this.$xhr('POST', '/logout', {}, function(code, response) {
			that.setCurrentUser(undefined);
			that.$location.path('signin')
		}, this.errorHandler);
	},
	hasRole: function(role) {
		if (!this.isUserSignedIn() || !this.currentUser.roles) return false
		return this.currentUser.roles.indexOf(role) >= 0
	},
	nextTask: function(cb) { var that = this
		this.$xhr('GET', '/tasks', function(code, bods) {
			that.$parent.$root.$emit('refresh_board_event');
			(cb || that.goto_task_view)(that.bod = bods[0])
		}, this.errorHandler)
	},
	goto_task_view: function(bod) {
		if (!bod) { return this.$window.alert('There is nothing to do at the moment') }
		var name = bod.name
		var sender = bod.ApplicationArea.Sender

		var view = undefined
		if (name == 'ProcessFax') view = '/backoffice-sales-rfq'
		if (name == 'ProcessSalesOrder' && sender == 'sales') view = '/sales-rfq'
		if (name == 'SyncSalesOrder' && sender == 'purchasing') view = '/purchasing-rfq'
		if (name == 'SyncSalesOrder' && sender == 'sales') view = '/sales-quote'
		if (name == 'ProcessRFQ') view = '/backoffice-supplier-rfq'
		if (name == 'ProcessQuote') view = '/backoffice-customer-quote'

		if (view) { this.$location.path(view) }
		else console.log('unknown bod name and sender:', name, sender)
	},
	newRFQ: function(){ var that = this
		this.$xhr('GET', '/process_rfq.json', function(code, res){
			that.bod = res
			that.$location.path('/backoffice-sales-rfq')
		})
	},
	newPO: function(){ var that = this
		this.$xhr('GET', '/process_po.json', function(code, res){
			that.bod = res
			that.$location.path('/backoffice-sales-po')
		})
	}
}

function RegisterController() {
}
RegisterController.prototype = {
	submit: function() {
		var r = new this.Registration({
			'email': this.email,
			'password': this.password,
			'password2': this.password2,
			'company_name': this.company_name
		});
		var that = this;
		r.$save({}, function(obj) {
			that.$location.path('/main');
			//the registered user will be automatically signed-in in the backend, so we need to get the current user
			that.loadCurrentUser();
		}, this.errorHandler);
	},
	cancel: function() {
		this.$location.path('/main');
	}
}

function SigninController() {
	this.email = this.getItem('email')
	var focus = 'email'
	if (this.email) focus = 'password'
	this.$defer(function(){ $('input[name="'+focus+'"]').focus() }, 100)
}
SigninController.prototype = {
	submit: function() {
		var r = new this.Login({
			'email': this.email,
			'password': this.password
		})
		var that = this;
		r.$save({}, function(obj) {
			that.setItem('email', that.email) //store email of last successful sign in
			that.$location.path('/main')
			that.loadCurrentUser()
			that.password = ''
		}, this.errorHandler)
	},
	cancel: function() {
		this.$location.path('/main')
	}
}

function SalesRFQController() { var that = this
	if (this.bod) init(); else this.nextTask(init)
	function init(){
		that.salesOrder = that.bod.DataArea.SalesOrder
		that.sender = that.salesOrder.SalesOrderHeader.CustomerParty
		that.sender_country = that.COUNTRY_CODES[that.sender.Location.Address.CountryCode]
			|| that.sender.Location.Address.CountryCode
		that.itemToMap = undefined
		// get out the inventory from the BOD
		var arr = that.bod.DataArea.PriceList.items
		that.map_count = {}
		that.inventory = Object.keys(arr).map(function(k){ that.map_count[k] = 0; return arr[k] })
	}
}
SalesRFQController.prototype = {
	mapItem: function(item) {
		this.itemToMap = item
		this.$defer(function(){ $('input[name="inventory_filter"]').focus() })
	},
	connectItem: function(inventoryItem) {
		if (!this.itemToMap) return
		//unmap the previously mapped inventoryItem
		if (this.itemToMap.CatalogReference.ItemID[0].ID) {
			this.map_count[this.itemToMap.CatalogReference.ItemID[0].ID]--
		}
		//map the new item
		this.itemToMap.CatalogReference.ItemID[0].ID = inventoryItem.id
		this.map_count[inventoryItem.id]++
		this.itemToMap = undefined
	},
	getItemClass: function(item) {
		if (this.itemToMap === item) return 'selected'
		if (item.CatalogReference.ItemID[0].ID) return 'mapped'
		return ''
	},
	getInventoryItemClass: function(inventoryItem) {
		return this.map_count[inventoryItem.id] ? 'mapped' : ''
	},
	done: function() {
		var that = this
		this.$xhr('POST', '/sales', this.bod, function(code, response){
			that.$parent.$root.$emit('refresh_board_event')
			that.flash = '<h2>RFQ mapping accepted!</h2>'
			that.$location.path('/main');
		}, this.errorHandler)
	}
}

function SalesQuoteController() { var that = this
	if (this.bod) init(); else this.nextTask(init)
	function init(){
		var SO = that.bod.DataArea.SalesOrder
		that.header = SO.SalesOrderHeader
		that.lines = SO.SalesOrderLine
		if (!that.lines[0].UserArea || !that.lines[0].UserArea.originalPrice) {
			that.lines.forEach(function(item){
				// In case of the "Map all RFQ items to inventory" scenario, there is no UserArea
				if (!item.UserArea) item.UserArea = {}
				item.UserArea.originalPrice = item.UnitPrice.Amount
			})
			that.lines.forEach(function(item){
				item.UnitPrice.Amount = Math.round(120 * item.UnitPrice.Amount) / 100.0
			})
		}
		that.prevQuotes = [
			{created: "2011-09-02T02:25:31.552Z",
				id: 14,
				quotationValue: 145.33,
				profitMargin: 15.04,
				won: true
			},
			{created: "2011-09-04T05:15:31.552Z",
				id: 179,
				quotationValue: 98.23,
				profitMargin: 23.12,
				won: false
			},
			{created: "2011-09-05T07:15:31.552Z",
				id: 234,
				quotationValue: 274.11,
				profitMargin: 18.87,
				won: true
			},
		]
		that.internal_discussion = [
			{process: 'Map inventory', chats: [
				{name: 'Chris', msg: 'Can i use the #600 steel pipe union for this order?', time: new Date(2011,11-1,4,19,38)},
				{name: 'Mike', msg: 'the japanese one? ok but charge him more', time: new Date(2011,11-1,5,19,45)}
			]},
			{process: 'Quote', chats: [
				{name: 'Derrick', msg: "I'll charge him 25% okay?", time: new Date(2011,11-1,6,11,54)},
				{name: 'Mike', msg: 'mmmm sure', time: new Date(2011,11-1,7,11,55)}
			]}
		]
	}
}
SalesQuoteController.prototype = {
	/** Calculate the profit margin for the actual Quote, which is
	* (Total quote price / Total cost price) - 1, but displayed as percents.
	* Total cost price is based on the item prices in the inventory.*/
	computeProfitMargin: function() {
		var totalCostPrice = 0
		var totalQuotePrice = 0
		for (var i in this.lines) {
			var item = this.lines[i]
			totalCostPrice += item.Quantity * item.UserArea.originalPrice
			totalQuotePrice += item.Quantity * item.UnitPrice.Amount
		}
		return (totalQuotePrice / totalCostPrice - 1.0) * 100
	},
	confirm: function() {
		$('link').attr('href', 'css/print.css')
		this.$location.path('/print-quote')
	}
}

function PrintQuoteController() { var that = this
	if (this.bod) init(); else this.nextTask(init)
	function init(){
		var SO = that.bod.DataArea.SalesOrder
		var PQ = that.bod.DataArea.Quote
		that.header = SO ? SO.SalesOrderHeader : PQ.QuoteHeader
		that.lines = SO ? SO.SalesOrderLine : PQ.QuoteLine
		that.date = new Date()
		$('link').attr('href', 'css/print.css')
	}
}
PrintQuoteController.prototype = {
	back: function() {
		$('link').first().attr('href', 'css/app.css')
		if (this.bod.DataArea.SalesOrder)
			this.$location.path('/sales-quote')
		else
			this.$location.path('/backoffice-customer-quote')
		this.$window.scrollTo(0, 0)
	},
	done: function() { var that = this
		this.$xhr('POST', '/sales', this.bod, function(code, response){
			that.$parent.$root.$emit('refresh_board_event')
			that.flash = '<h2>Quote accepted!</h2>'
			that.$location.path('/main');
			$('link').first().attr('href', 'css/app.css')
		}, this.errorHandler)
	}
}

function PrintRFQController() { var that = this
	if (this.bod) init(); else this.nextTask(init)
	function init(){
		var RFQ = that.bod.DataArea.RFQ
		that.header = RFQ.RFQHeader
		that.lines = RFQ.RFQLine
		that.date = new Date()
		$('link').attr('href', 'css/print.css')
	}
}
PrintRFQController.prototype = {
	back: function() {
		$('link').first().attr('href', 'css/app.css')
		this.$location.path('/backoffice-supplier-rfq')
		this.$window.scrollTo(0, 0)
	},
	done: function() { var that = this
		this.$xhr('POST', '/sales', this.bod, function(code, response){
			that.$parent.$root.$emit('refresh_board_event')
			that.flash = '<h2>RFQ printed!</h2>'
			that.$location.path('/main')
			$('link').first().attr('href', 'css/app.css')
		}, this.errorHandler)
	}
}

function BackofficeCustomerQuoteController(){ var that = this
	if (this.bod) init(); else this.nextTask(init)
	function init(){
		var PQ = that.bod.DataArea.Quote
		that.header = PQ.QuoteHeader
		that.lines = PQ.QuoteLine
	}
}
BackofficeCustomerQuoteController.prototype = {
	printPreview: function(){
		$('link').attr('href', 'css/print.css')
		this.$location.path('/print-quote')
		this.$window.scrollTo(0, 0)
	}
}

function BackofficeSalesRFQController(){ var that = this
	if (this.bod) init(); else this.nextTask(init)
	function init() {
		that.image_width = 500
		that.rotate = 0
		if (!that.bod.image || that.bod.image == 'RFQ') {
			if (that.bod.demoProcessRFQ) that.bod.ProcessRFQ = that.bod.demoProcessRFQ
			that.rfq = that.bod.ProcessRFQ.DataArea.RFQ
			that.rfq.RFQHeader.DocumentID.ID = angular.filter.date.call(that, new Date(), 'dd.MM')
			if (that.rfq.RFQLine.length == 0) that.rfq.RFQLine.push({})
			that.rfq.RFQHeader.DocumentDateTime = new Date()
		} else {
			that.quote = that.bod.ProcessQuote.DataArea.Quote
		}
	}
}
BackofficeSalesRFQController.prototype = {
	addItem: function() {
		if (this.rfq.RFQLine.length > 0 && this.rfq.RFQLine[this.rfq.RFQLine.length - 1].Description) {
			this.rfq.RFQLine.push({});
		}
		this.$root.$eval();
		this.$defer(function(){
			$('input[name="item.Quantity"]').last().focus();
		})
	},
	deleteItem: function(itemIndex) {
		this.rfq.RFQLine.splice(itemIndex, 1);
		if (this.rfq.RFQLine.length == 0) {
				this.rfq.RFQLine.push({Quantity: 1});
		}
		this.$root.$eval();
		this.$defer(function(){
			$('input[name="item.Quantity"]').last().focus();
		});
	},
	send: function() {
		//set LineNumber for each item
		for (var i in this.rfq.RFQLine) {
			this.rfq.RFQLine[i].LineNumber = parseInt(i) + 1;
			this.rfq.RFQLine[i].Quantity_unitCode = null;
		}
		var that = this;
		this.$xhr('POST', '/sales', this.bod.ProcessRFQ, function(code, response){
			that.$parent.$root.$emit('refresh_board_event')
			console.log('sent rfq:', response);
			if (response.status == 'ok') {
				that.flash = '<h2>RFQ accepted!</h2>'
				that.$location.path('/main');
			} else {
				that.$window.alert('Error: '+response.status+' '+response.msg);
			}
		}, this.errorHandler);
	},
	magnify_plus: function(){
		this.image_width = Math.round(1.25 * this.image_width)
	},
	magnify_minus: function(){
		this.image_width = Math.round(0.8 * this.image_width)
	},
	upside_down: function(){
		this.rotate = this.rotate ? 0 : 180
	}
}

function PurchasingRFQController() { var that = this
	if (this.bod) init(); else this.nextTask(init)
	function init() {
		that.salesOrder = that.bod.DataArea.SalesOrder
		that.sender = that.salesOrder.SalesOrderHeader.CustomerParty
		that.sender_country = that.COUNTRY_CODES[that.sender.Location.Address.CountryCode]
			|| that.sender.Location.Address.CountryCode
		var arr = that.bod.DataArea.SupplierPartyMaster
		that.supplier_map_count = {}
		that.suppliers = Object.keys(arr).map(function(k){ that.supplier_map_count[k] = 0; return arr[k] })
		that.itemToMap = undefined
	}
}
PurchasingRFQController.prototype = {
	mapItem: function(item) {
		this.itemToMap = item
		this.$defer(function(){ $('input[name="supplier_filter"]').focus() })
	},
	connectItem: function(supplier) {
		if (!this.itemToMap) return
		//unmap the previously mapped supplier
		if (this.itemToMap.UserArea.SupplierID) { this.supplier_map_count[this.itemToMap.UserArea.SupplierID]-- }
		//map the new item
		this.itemToMap.UserArea.SupplierID = supplier.PartyIDs.ID[0]
		this.supplier_map_count[supplier.PartyIDs.ID[0]]++
		this.itemToMap = undefined
	},
	getItemClass: function(item) {
		if (this.itemToMap === item) return 'selected'
		if (item.UserArea.SupplierID) return 'mapped'
		return ''
	},
	getSupplierClass: function(supplier) {
		return this.supplier_map_count[supplier.PartyIDs.ID[0]] ? 'mapped' : ''
	},
	send: function() { var that = this
		this.$xhr('POST', '/sales', this.bod, function(code, response){
			that.$parent.$root.$emit('refresh_board_event')
			that.flash = '<h2>Supplier mapping accepted!</h2>'
			that.$location.path('/main');
		}, this.errorHandler)
	}
}

function BackofficeSupplierRFQController(){ var that = this
	if (this.bod) init(); else this.nextTask(init)
	function init() {
		that.docs = []
		that.docs.push({
			type: 'rfq',
			rfq: that.bod.DataArea.RFQ,
			quote: that.bod.ProcessQuote.DataArea.Quote,
			sent: 'Sent'
		})
	}
}
BackofficeSupplierRFQController.prototype = {
	phone: function(doc) {
		if (!doc.rfq.RFQHeader.SupplierParty.Contact.Communication.UserArea.Phone) {
			return this.$window.alert('Please provide phone number!')
		}
		doc.type = 'quote'
	},
	done: function(doc) {
		// make sure all items have price
		for (var i in doc.quote.QuoteLine) {
			var item = doc.quote.QuoteLine[i]
			if (!item.UnitPrice.Amount) {
				return this.$window.alert('All items should have price!')
			}
		}
		doc.type = 'sent'
		// if all quote are sent then send the bod to the backend
		var all = true
		for(var i in this.docs) {
			if (this.docs[i].type != 'sent') {
				all = false
				break
			}
		}
		if (all) {
			var that = this
			this.$xhr('POST', '/sales', that.bod.ProcessQuote, function(code, response){
				that.$parent.$root.$emit('refresh_board_event')
				that.flash = '<h2>Sourcing accepted!</h2>'
				that.$location.path('/main');
			}, this.errorHandler)
		}
	},
	printPreview: function(){
		$('link').attr('href', 'css/print.css')
		this.$location.path('/print-rfq')
		this.$window.scrollTo(0, 0)
	}
}

function BackofficeSalesQuoteController(){ var that = this
	if (this.bod) init(); else this.nextTask(init)
	function init() {
		that.quote = that.bod.ProcessQuote.DataArea.Quote
		that.sender = that.quote.QuoteHeader.SupplierParty
		that.sender_country = that.COUNTRY_CODES[that.sender.Location.Address.CountryCode]
			|| that.sender.Location.Address.CountryCode
	}
}

function BoardController() {
	this.lane_headings = {
		customer: "Customer",
		backoffice: "Backoffice",
		sales: "Sales",
		billing: "Billing",
		accounting: "Accounting",
		logistics: "Logistics",
		warehouse: "Warehouse",
		purchasing: "Purchasing",
		supplier: "Supplier",
		done: "Done"
	}
	this.lanes = ['customer', 'backoffice', 'sales', 'billing', 'warehouse', 'purchasing', 'done']
	this.refresh()
	var that = this
	this.$parent.$root.$on('refresh_board_event', function(){
		that.refresh()
	})
}
BoardController.prototype = {
	refresh: function() { var that = this
		this.$xhr('GET', '/api/board',
			function(code, res) { that.cards = res }, that.errorHandler )
	}
}
function BoardExamplesController() { var that = this
	this.lane_headings = {
		customer: "Customer",
		backoffice: "Backoffice",
		sales: "Sales",
		purchasing: "Purchasing",
		done: "Done / Customer"
	}

	this.boards = [
		{ name: "Example", lanes: {
			backoffice: [
				["Quote", '#SOID Eagle Tech Oilfield', true],
				["inQuote", '#SOID Lim Soon Supplies (3/3)', false]
			],
			sales: [ ["RFQ", '#SOID Sophie Supplies', true] ],
			purchasing: [ ["Source", '#SOID Techlink Supplies', false] ],
			done: [ ["Quote", '#SOID Techlink Oilfields', true] ]
		}},
		{ name: "Empty", lanes: {
			customer: [],
			backoffice: [ ["", "", true] ],
			sales: [],
			purchasing: [],
			done: []
		}},
		{ name: "<b>1.</b> Fax arrived", lanes: {
			customer: [
				["FAX", "in", true]
			],
			backoffice: [],
			sales: [],
			purchasing: [],
			done: []
		}},
		{ name: "<b>2.</b> Processing Fax", lanes: {
			customer: [],
			backoffice: [ ["FAX", "processing...", false] ],
			sales: [],
			purchasing: [],
			done: []
		}},
		{ name: "<b>3.</b> RFQ ready", lanes: {
			customer: [],
			backoffice: [ ["RFQ#V-1009", "Sophie Supply", true] ],
			sales: [],
			purchasing: [],
			done: []
		}},
		{ name: "<b>4.</b> Mapping inventory to RFQ", lanes: {
			customer: [],
			backoffice: [],
			sales: [ ["RFQ#V-1009 SO#1234", "<br>mapping inventory...<br>Sophie Supply", false] ],
			purchasing: [],
			done: []
		}},
		{ name: "<b>5.</b> Inventory mapped", lanes: {
			customer: [],
			backoffice: [],
			sales: [ ["SO#1234 RFQ#V-1009", "Sophie Supply", true] ],
			purchasing: [],
			done: []
		}},
		{ name: "<br><em>Scenario 1: Inventory fully mapped:</em> <b>6.</b> Pricing SO", lanes: {
			customer: [],
			backoffice: [],
			sales: [ ["RFQ#V-1009 SO#1234", "<br>pricing...<br>Sophie Supply", false] ],
			purchasing: [],
			done: []
		}},
		{ name: "<b>7.</b> Quote ready", lanes: {
			customer: [],
			backoffice: [],
			sales: [ ["Quote RFQ#V-1009 SO#1234", "Sophie Supply", true] ],
			purchasing: [],
			done: []
		}},		
		{ name: "<b>8.</b> Sending Quote", lanes: {
			customer: [],
			backoffice: [ ["Quote RFQ#V-1009 SO#1234", "<br>sending...<br>Sophie Supply", false] ],
			sales: [],
			purchasing: [],
			done: []
		}},		
		{ name: "<b>9.</b> Quote sent", lanes: {
			customer: [],
			backoffice: [ ["Quote RFQ#V-1009 SO#1234", "Sophie Supply", true] ],
			sales: [],
			purchasing: [],
			done: []
		}},		
		{ name: "<br><em>Scenario 2: Inventory NOT fully mapped:</em> <b>10.</b> Mapping suppliers to SO", lanes: {
			customer: [],
			backoffice: [],
			sales: [],
			purchasing: [ ["SO#1234 RFQ#V-1009", "<br>mapping suppliers...<br>Sophie Supply", false] ],
			done: []
		}},
		{ name: "<b>11. (tom)</b> outRFQs ready", lanes: {
			customer: [],
			backoffice: [],
			sales: [],
			purchasing: [
				["outRFQ#??? SO#1234 RFQ#V-1009", "Lim Soon Supplies", true],
				["outRFQ#??? SO#1234 RFQ#V-1009", "Eagle Tech Oilfield", true],
				["outRFQ#??? SO#1234 RFQ#V-1009", "Alparts Tdg Ent", true]
			],
			done: []
		}},
		{ name: "<b>11. (hansel)</b> Source SO", lanes: {
			customer: [],
			backoffice: [],
			sales: [],
			purchasing: [ ["Source SO#1234", "Sophie Supply", true] ],
			done: []
		}},
		{ name: "<b>12. (hansel)</b> Sourcing SO", lanes: {
			customer: [],
			backoffice: [ ["Source SO#1234", "<br>sourcing...<br>Sophie Supply", false] ],
			sales: [],
			purchasing: [],
			done: []
		}},
		{ name: "<b>13. (hansel)</b> All quotes came back", lanes: {
			customer: [],
			backoffice: [ ["Quotes SO#1234", "Sophie Supply", true] ],
			sales: [],
			purchasing: [],
			done: []
		}},
	]
	this.$watch('lane_texts', function(){
		try { that.cards = JSON.parse(that.lane_texts)
		that.lanes = Object.keys(that.cards)
		 } catch (e) {}
	})
}

BoardExamplesController.prototype = {
	set_lane_texts: function(new_lane_texts) {
		console.log('new_lanes:', new_lane_texts)
		this.lane_texts = JSON.stringify(new_lane_texts, null, "  ")
	}
}

function MainController() {
	this.lane_headings = {}
	this.lanes = []
	/*
	this.lane_headings = {
		customer: "Customer",
		backoffice: "Backoffice",
		sales: "Sales",
		billing: "Billing",
		accounting: "Accounting",
		logistics: "Logistics",
		warehouse: "Warehouse",
		purchasing: "Purchasing",
		supplier: "Supplier",
		done: "Done"
	}
	this.lanes = ['customer', 'backoffice', 'sales', 'billing', 'warehouse', 'purchasing', 'done']
	*/
	this.refresh()
	var that = this
	this.chat_socket.on('msg', function (data) {
		that.chat_lines.push(data)
		that.$digest()
		that.$defer(function(){
			try { $('#chat_window')[0].scrollTop = 9999 } catch (e) {}
		})
	})
	this.chat_socket.on('lines', function(data){
		that.chat_lines = data.lines
		that.$digest()
		that.$defer(function(){
			try { $('#chat_window')[0].scrollTop = 9999 } catch (e) {}
		})
	})
	this.chat_socket.emit('lines', {})
}
MainController.prototype = {
	refresh: function() { var that = this
		this.$xhr('GET', '/api/board',
			function(code, res) { that.cards = res 
	that.lane_headings = {
		customer: "Customer",
		backoffice: "Backoffice",
		sales: "Sales",
		billing: "Billing",
		accounting: "Accounting",
		logistics: "Logistics",
		warehouse: "Warehouse",
		purchasing: "Purchasing",
		supplier: "Supplier",
		done: "Done"
	}
	that.lanes = ['customer', 'backoffice', 'sales', 'billing', 'warehouse', 'purchasing', 'done']
	

			}, that.errorHandler )
	},
	sendMsg: function(){
		var data = {msg: this.message, name: this.currentUser.name, time: new Date()}
		this.chat_lines.push(data)
		this.chat_socket.emit('msg', data)
		this.message = ''
		this.$defer(function(){
			$('#chat_window')[0].scrollTop = 9999
		})
	},
	getClassForMsg: function(line) {
		if (line.name == this.currentUser.name) {
			return 'my-message'
		}
	}
}

function BackofficeSalesPOController(){ var that = this
	if (this.bod) init(); else this.nextTask(init)
	function init() {
		that.po = that.bod.DataArea.PurchaseOrder
		that.po.PurchaseOrderHeader.DocumentID.ID = angular.filter.date.call(that, new Date(), 'dd.MM')
		if (that.po.PurchaseOrderLine.length == 0) that.po.PurchaseOrderLine.push({})
	}
}
BackofficeSalesPOController.prototype = {
	send: function() {
		//set LineNumber for each item
		for (var i in this.po.PurchaseOrderLine) {
			this.po.PurchaseOrderLine[i].LineNumber = parseInt(i) + 1;
			this.po.PurchaseOrderLine[i].Quantity_unitCode = null;
		}
		var that = this;
		this.$xhr('POST', '/sales', this.bod, function(code, response){
			that.$parent.$root.$emit('refresh_board_event')
			console.log('sent po:', this.bod, 'response:', response)
			if (response.status == 'ok') {
				that.flash = '<h2>Purchase order accepted!</h2>'
				that.$location.path('/')
			} else {
				that.$window.alert('Error: '+response.status+' '+response.msg)
			}
		}, this.errorHandler)
	},
}