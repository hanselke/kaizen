var vows = require('vows'),
	assert = require('assert'),
	request = require('request'),
	oagis = require('../../oagis'),
	ourselves = require('../../ourselves').party

var server_url = 'http://localhost:8001';
var cookies = {}
var current_role = '', debug = ''
function current_session_is(role, res) { cookies[role] = res.headers['set-cookie'].pop().split(';')[0] }
function current_session() {
	var sess = cookies[current_role]
	return sess ? {'cookie': sess } : {}
}
function post(path, obj, cb) {
	var url = server_url + path + (debug ? '?' + debug.replace(/ /g, '_') : ''); debug = ''
	request.post( {url: url, jar: false, json: obj, headers: current_session()}, cb )
}
function get(path, cb) {
	var url = server_url + path + (debug ? '?' + debug.replace(/ /g, '_') : ''); debug = ''
	request.get( {url: url, jar: false, json: true, headers: current_session()}, cb )
}
function ProcessRFQ(bod) {
	bod.DataArea.RFQ.RFQHeader.CustomerParty
		.Contact.Communication.UserArea.Email = 'customer@company.com';
	item = bod.DataArea.RFQ.RFQLine[0]
	item.LineNumber = 1
	item.Description = '45" Elbow'
	item.Quantity = 12
	item.Quantity_unitCode = "each"
	return bod
}
function getLine(lines, num) { for (var i in lines) if (lines[i].LineNumber == num) return lines[i] }

var users = {
	backoffice: { company_name: "Guan Huat", email: "backoffice@x.y", password: "b", password2: "b", roles: ['backoffice'] },
	customer: { company_name: "Sophia Supply", email: "supply@x.y",	password: "c", password2: "c", roles: ['customer'] },
	sales: { company_name: "Open Business Pte Ltd", email: "sales@x.y", password: "s", password2: "s", roles: ['sales'] },
	purchasing: { company_name: "Open Business Pte Ltd", email: "purchasing@x.y", password: "p", password2: "p", roles: ['purchasing'] },
	buyer: { company_name: "Guan Huat", email: "derrick@x.y", password: "b", password2: "b", roles: ['buyer'] }
}

function register(role, cb) {
	return {		// return a vows context
		topic: function() { var that = this
			post("/users", users[role], function(e, res, body) {
				if (res.statusCode != 200)
					that.callback(e, res, body)
				else
					post('/login', users[role], function(e, res, body) {
						current_session_is(role, res)
						that.callback(e, res, body)
					})
			})
		 }, 'ok': function(e, res, body) { assert.equal(res.statusCode, 200) }
	}
}

function unauthorized(e, res, body) { assert.equal(res.statusCode, 401) }
function forbidden(e, res, body) { assert.equal(res.statusCode, 403) }
function not_found(e, res, body) { assert.equal(res.statusCode, 404) }
function conflict(e, res, body) { assert.equal(res.statusCode, 409) }

exports.registration = vows.describe(
'Registration\n\
	As a visitor\n\
	I should be able to register with my\n\
	- email\n\
	- company name\n\
	- password\n\
	So I can ???',
{
	"As a Visitor": {
		topic: function() { var that = this; cookies = {}; current_role = ''
			post("/init_db", {}, function() { post("/restart", {}, that.callback) })
		}, '': function(){}
	}
},
{
	"WHEN I submit my details": {
		topic: function() { var that = this
			post('/users', users.buyer, function(e, res, body) {
				that.callback(null, body, users.buyer)
			})
		},
		"THEN I should get my details back": function(e, details, buyer) {
			assert.equal(details.company_name, buyer.company_name)
			assert.equal(details.email, buyer.email)
		},
		"without my password": function(e, details, buyer) {
			assert.isUndefined(details.password)
			assert.isUndefined(details.password2)
		},
		"with a newly assigned user ID": function(e, details, buyer) {
			assert.include(details, 'id')
		},
		"ID should be ???": "pending",
		"AND I should be logged in": "pending",
		"AND I should get a confirmation email": "pending",
		"AND I try to register later again": {
			topic: function(details, buyer) { var that = this
				post("/restart", {}, function() {
					post('/users', buyer, function(e, res, body) {
						that.callback(null, res, buyer)
					})
				})
			},
			"THEN I can't, because the system remembers me": conflict
		}
	}
},
{
	"GIVEN I'm logged in": {
		topic: function() { var that = this
			var role = 'buyer'
			post('/login', users[role], function(e, res, body) {
				current_session_is(role, res)
				current_role = role
				that.callback()
			})
		},
		"WHEN I try to register again": {
			topic: function() { post('/users', users.buyer, this.callback) },
			"THEN it should be forbidden": forbidden
		}
	}
})

exports.process_fax = vows.describe(
'Fax data entry\n\
	In order to create BODs\n\
	As a Backoffice user\n\
	I should see a Fax, so I can copy the data into a selected BOD skeleton',
{
	"": {
		topic: function() { var that = this; cookies = {}; current_role = ''
			post("/init_db", {}, function() { post("/restart", {}, that.callback) })
		},
		"Having a Backoffice user": register("backoffice")
	},
},
{
	"GIVEN a Fax has arrived": {
		topic: function() { post('/faxes', {image: "RFQ"}, this.callback) },
		"\n    WHEN the Backoffice user asks for the next task": {
			topic: function() { current_role = 'backoffice'; get('/tasks', this.callback) },
			"THEN he should get the same Fax image": function(e, res, tasks) {
				assert.lengthOf(tasks, 1);
				assert.equal(tasks[0].name, 'ProcessFax')
				assert.include(tasks[0], 'image')
				assert.equal(tasks[0].image, 'RFQ')
			},
			"AND a ProcessRFQ skeleton": function(e, res, tasks) {
				assert.include(tasks[0], 'ProcessRFQ')
				assert.equal(tasks[0].ProcessRFQ.name, 'ProcessRFQ')
				assert.equal(tasks[0].ProcessRFQ.ApplicationArea.Sender, 'backoffice')
				assert.equal(tasks[0].ProcessRFQ.ApplicationArea.Receiver, 'sales')
			},
			"which links to the Fax image": function(e, res, tasks) {
				var ProcessFax = tasks[0]
				assert.equal(
					ProcessFax.ProcessRFQ.DataArea.RFQ.RFQHeader.DocumentReference.DocumentID.ID,
					ProcessFax.ApplicationArea.BODID)
			},
			"\n    WHEN we have a look at the board": {
				topic: function(res, tasks) { var that = this
					get('/board', function(e,r,board) { that.callback(e,board,tasks[0]) })
				},
				"THEN we should see a Fax card in the Backoffice lane": function(e, board, task) {
						assert.deepEqual(board.backoffice, [{id: "FAX", desc: "processing...", ready: false}])
						assert.isEmpty(board.sales)
						assert.isEmpty(board.purchasing)
						assert.isEmpty(board.done)
				}
			}
		}
	}
})

exports.submit_rfq = vows.describe(
'Submit RFQ\n\
	In order to get prices for parts I want to buy\n\
	As a Customer or Backoffice user\n\
	I should be able to submit an RFQ to Sales',
{
	"": {
		topic: function() { var that = this; cookies = {}; current_role = ''
			post("/init_db", {}, function() { post("/restart", {}, that.callback) })
		},
		"Having a Backoffice user": register("backoffice"),
		"Having a Sales man": register("sales")
	}
},
{
	"GIVEN a Fax has arrived": {
		topic: function() { post('/faxes', {image: "RFQ"}, this.callback) },
		"\n    WHEN the Backoffice user asks for the next task": {
			topic: function() { current_role = 'backoffice'; get('/tasks', this.callback) },
			"he gets empty forms,": {
				topic: function(res, tasks) { return tasks[0].demoProcessRFQ },
				"\n    WHEN he submits the ProcessRFQ form": {
					topic: function(rfq) { current_role = 'backoffice'; post('/sales', rfq, this.callback) },
					"THEN he should get a confirmation": function (e,r,body) {
						assert.equal(body.status, "ok")
					},
					"\n    WHEN we have a look at the board": {
						topic: function(r,b, rfq) { var that = this
							get('/board', function(e,r,board) { that.callback(e, board, rfq) })
						},
						"THEN we should see a ready RFQ card in the Backoffice lane": function(e, board, rfq) {
							var header = rfq.DataArea.RFQ.RFQHeader
							assert.deepEqual(board.backoffice, [{
								id: 'RFQ#'+header.DocumentID.ID,
								desc: '<br>'+header.CustomerParty.Name,
								ready: true
							}])
							assert.isEmpty(board.sales)
							assert.isEmpty(board.purchasing)
							assert.isEmpty(board.done)
						},
						"\n    WHEN a Sales man asks for the next task": {
							topic: function(board, rfq) { var that = this
								current_role = 'sales'
								get('/tasks', function(e, res, body) { that.callback(e, body, rfq) })
							},
							"THEN he should get 1 ProcessSalesOrder": function(e, tasks, rfq) {
								assert.lengthOf(tasks, 1);
								assert.equal(tasks[0].name, "ProcessSalesOrder");
								assert.equal(tasks[0].ApplicationArea.Sender, 'sales')
								assert.equal(tasks[0].ApplicationArea.Receiver, 'sales')
							},
							"which has a PriceList": function(e, tasks, rfq) {
								assert.include(tasks[0].DataArea, "PriceList");
							},
							"has the same number of line items as the RFQ": function(e, tasks, rfq) {
								assert.lengthOf(tasks[0].DataArea.SalesOrder.SalesOrderLine, rfq.DataArea.RFQ.RFQLine.length)
							},
							"each line item has CatalogReference": function(e, tasks, rfq) {
								assert.include(tasks[0].DataArea.SalesOrder.SalesOrderLine[0], 'CatalogReference')
							},
							"has the same Customer": function(e, tasks, rfq) {
								assert.deepEqual(
									tasks[0].DataArea.SalesOrder.SalesOrderHeader.CustomerParty,
									rfq.DataArea.RFQ.RFQHeader.CustomerParty)
							},
							"\n    WHEN we have a look at the board": {
								topic: function(tasks, rfq) { var that = this
									get('/board', function(e,r,board) { that.callback(e, board, rfq) })
								},
								"THEN we should see a WIP RFQ card in the Sales lane": function(e, board, rfq) {
										assert.isEmpty(board.backoffice)
										var header = rfq.DataArea.RFQ.RFQHeader
										assert.deepEqual(board.sales, [{
											id: 'RFQ#'+header.DocumentID.ID,
											desc: '<br>'+header.CustomerParty.Name+'<br>mapping inventory...',
											ready: false
										}])
										assert.isEmpty(board.purchasing)
										assert.isEmpty(board.done)
								}
							}
						}
					}
				}
			}
		}
	}
},
{
	"GIVEN and empty DB": {
		topic: "",
		"WHEN a Sales man asks for his next task": {
			"THEN he should get an empty list": "pending"
		}
	}
})


var init_backoffice_customer_sales = {
	"": {
		topic: function() { var that = this; cookies = {}; current_role = ''; debug = this.suite.subject
			post("/init_db", {}, function() { post("/restart", {}, that.callback) })
		},
		"Having a Backoffice user": register("backoffice"),
		"Having a Customer": register("customer"),
		"Having a Sales man": register("sales")
	}
}

var init_mapping = {
	"GIVEN a Fax has arrived": {
		topic: function() { post('/faxes', {image: "RFQ"}, this.callback) },
		"\n    WHEN the Backoffice user asks for the next task": {
			topic: function() { current_role = 'backoffice'; get('/tasks', this.callback) },
			"he gets empty forms,": {
				topic: function(res, tasks) {return tasks[0].demoProcessRFQ},
				"\n    WHEN he submits the ProcessRFQ form": {
					topic: function(rfq) { current_role = 'backoffice'; post('/sales', rfq, this.callback) },
					'': function(){}
}}}}}

/*
'Map RFQ to inventory\n\
	In order to quote prices\n\
	As a Sales man\n\
	I should be able to identify which inventory item each RFQ line means'
*/

exports.map_all_rfq = vows.describe('Map all RFQ items to inventory',
init_backoffice_customer_sales,
init_mapping,
{
	"AND a Sales man asks for the next task": {
		topic: function() { var that = this
			current_role = 'sales'
			get('/tasks', function(e, res, tasks) { that.callback(null, tasks[0]) })
		},
		"\n    WHEN he submits a full inverntory mapping": {
			topic: function(sales_order){ var that = this
				var inventory_ids = Object.keys(sales_order.DataArea.PriceList.items)
				sales_order.DataArea.SalesOrder.SalesOrderLine.forEach(function(item, index){
					item.CatalogReference.ItemID[0].ID = inventory_ids[index]
				})
				post('/sales', sales_order, function(e, r, body) { that.callback(e, body, sales_order) })
			},
			"THEN he should get a confirmation": function(e, body, sales_order) {
				assert.equal(body.status, "ok")
			},
			"\n    WHEN a Sales man asks for the next task again": {
				topic: function(body, sales_order) { var that = this
					get('/tasks', function(e, res, tasks) { that.callback(null, tasks, sales_order) })
				},
				"THEN he should get 1 SyncSalesOrder": function(e, tasks, sales_order) {
					assert.lengthOf(tasks, 1)
					assert.equal(tasks[0].name, "SyncSalesOrder")
					assert.equal(tasks[0].ApplicationArea.Sender, 'sales')
					assert.equal(tasks[0].ApplicationArea.Receiver, 'sales')
				},
				"has the same number of line items as the previous SalesOrder": function(e, tasks, sales_order) {
					assert.lengthOf(tasks[0].DataArea.SalesOrder.SalesOrderLine,
						sales_order.DataArea.SalesOrder.SalesOrderLine.length)
				},
				"which has fields for prices": function(e, tasks, sales_order) {
					assert.isNotEmpty(tasks[0].DataArea.SalesOrder.SalesOrderLine)
					tasks[0].DataArea.SalesOrder.SalesOrderLine.forEach(function(item){
						var inventory_item = sales_order.DataArea.PriceList.items[item.CatalogReference.ItemID[0].ID]
						assert.include(item, "UnitPrice")
						assert.include(item.UnitPrice, "Amount")
						assert.equal(item.UnitPrice.Amount, inventory_item.price)
					})
				},
			}
		}
	}
})

exports.map_partial_rfq = vows.describe('Map RFQ items to inventory partially',
init_backoffice_customer_sales,
{"Having a Purchasing user": register('purchasing')},
init_mapping,
{
	"AND a Sales man asks for the next task": {
		topic: function() { var that = this
			current_role = 'sales'
			get('/tasks', function(e, res, tasks) { that.callback(null, tasks[0]) })
		},
		"\n    WHEN he submits a partial inverntory mapping": {
			topic: function(sales_order){
				// Map the 1st line item only
				var inventory_ids = Object.keys(sales_order.DataArea.PriceList.items)
				var item = sales_order.DataArea.SalesOrder.SalesOrderLine[0]
				item.CatalogReference.ItemID[0].ID = inventory_ids[0]
				
				var that = this
				post('/sales', sales_order, function(e, r, body) { that.callback(e, body, sales_order) })
			},
			"THEN he should get a confirmation": function(e, body, sales_order) {
				assert.equal(body.status, "ok")
			},
			"\n    WHEN we have a look at the board": {
				topic: function(body, sales_order) { var that = this
					get('/board', function(e,r,board) { that.callback(e, board, sales_order) })
				},
				"THEN we should see a ready inventory mapped RFQ card in the Sales lane":
				function(e, board, sales_order) {
					assert.isEmpty(board.backoffice)
					var header = sales_order.DataArea.SalesOrder.SalesOrderHeader
					assert.deepEqual(board.sales, [{
						id: 'RFQ#V-1009',
						desc: '<br>'+header.CustomerParty.Name+'<br><em>inventory mapped</em>',
						ready: true
					}])
					assert.isEmpty(board.purchasing)
					assert.isEmpty(board.done)
				},
				"\n    WHEN a Sales man asks for tasks again": {
					topic: function(board, sales_order) { var that = this
						get('/tasks', function(e, res, tasks) { that.callback(null, tasks, sales_order) })
					},
					"THEN he should not get any tasks yet": function(e, tasks, sales_order) {
						assert.isEmpty(tasks)
					},
					"\n    BUT WHEN a Purchasing user asks for tasks": {
						topic: function(body, sales_order) { var that = this
							current_role = 'purchasing'
							get('/tasks', function(e, res, tasks) { that.callback(null, tasks, sales_order) })
						},
						"THEN he should get 1 SyncSalesOrder": function(e, tasks, sales_order){
							assert.lengthOf(tasks, 1)
							assert.equal(tasks[0].name, 'SyncSalesOrder')
							assert.equal(tasks[0].ApplicationArea.Sender, 'purchasing')
							assert.equal(tasks[0].ApplicationArea.Receiver, 'sales')
						},
						"which has a SalesOrder ID": function(e, tasks, sales_order){
							assert.isNotNull(tasks[0].DataArea.SalesOrder.SalesOrderHeader.DocumentID.ID)
						},
						"which has fields for Supplier references": function(e, tasks, sales_order){
							var original_items = sales_order.DataArea.SalesOrder.SalesOrderLine
							var mapped_item_desc = original_items[0].Description
							var new_items = tasks[0].DataArea.SalesOrder.SalesOrderLine
							assert.lengthOf(new_items, original_items.length - 1)
							new_items.forEach(function(item){
								assert.include(item, 'UserArea')
								assert.include(item.UserArea, 'SupplierID')
								assert.notEqual(item.Description, mapped_item_desc)
							})
						},
						"which has a Supplier list": function(e, tasks, sales_order){
							assert.include(tasks[0].DataArea, 'SupplierPartyMaster')
						},
						"which doesn't have a PriceList": function(e, tasks, sales_order){
							assert.isUndefined(tasks[0].DataArea.PriceList)
						},
						"\n    WHEN we have a look at the board": {
							topic: function(tasks, sales_order) { var that = this
								get('/board', function(e,r,board) { that.callback(e, board, tasks[0], sales_order) })
							},
							"THEN we should see a WIP mapping suppliers card in the Purchasing lane":
							function(e, board, sync_sales_order, sales_order) {
								assert.isEmpty(board.backoffice)
								assert.isEmpty(board.sales)
								var header = sync_sales_order.DataArea.SalesOrder.SalesOrderHeader
								assert.deepEqual(board.purchasing, [{
									id: 'RFQ#V-1009', // SO#'+header.DocumentID.ID,
									desc: '<br>'+header.CustomerParty.Name+'<br><em>mapping suppliers...</em>',
									ready: false
								}])
								assert.isEmpty(board.done)
							}
						}
					}
				}
			}
		}
	}
})

exports.map_suppliers = vows.describe('Map suppliers to RFQ items',
init_backoffice_customer_sales,
{"Having a Purchasing user": register('purchasing')},
init_mapping,
{
	"\n    AND a Sales man asks for the next task": {
		topic: function() { var that = this
			current_role = 'sales'
			get('/tasks', function(e, res, tasks) { that.callback(null, tasks[0]) })
		},
		"\n    AND he submits a partial inverntory mapping": {
			topic: function(sales_order){
				// Map the 1st line item only
				var inventory_ids = Object.keys(sales_order.DataArea.PriceList.items)
				var item = sales_order.DataArea.SalesOrder.SalesOrderLine[0]
				item.CatalogReference.ItemID[0].ID = inventory_ids[0]
				post('/sales', sales_order, this.callback)
			},
			"\n    AND a Purchasing user asks for tasks": {
				topic: function() { var that = this
					current_role = 'purchasing'
					get('/tasks', function(e, res, tasks) { that.callback(null, tasks[0]) })
				},
				"THEN It should have at least 3 items": function(e, sync_sales_order) {
					var items = sync_sales_order.DataArea.SalesOrder.SalesOrderLine
					assert.strictEqual(items.length >= 3, true)
				},
				"\n    AND he submits the SyncSalesOrder with supplier mapping for 2 suppliers": {
					topic: function(sync_sales_order) { var that = this
						var items = sync_sales_order.DataArea.SalesOrder.SalesOrderLine
						var supplier_ids = Object.keys(sync_sales_order.DataArea.SupplierPartyMaster)
						// map the first 2 items to a supplier
						items[0].UserArea.SupplierID = supplier_ids[0]
						items[1].UserArea.SupplierID = supplier_ids[0]
						// map all other items to an other supplier
						for (var i = 2; i < items.length; i++) {
							items[i].UserArea.SupplierID = supplier_ids[1]
						}
						post('/sales', sync_sales_order, function(e, r, body) { that.callback(e, body, sync_sales_order) })
					},
					"THEN he should get a confirmation": function(e, body, sync_sales_order) {
						assert.isObject(body)
						assert.equal(body.status, "ok")
					},
					"\n    WHEN we have a look at the board": {
						topic: function(body, sync_sales_order) { var that = this
							get('/board', function(e,r,board) { that.callback(e, board, sync_sales_order) })
						},
						"THEN we should see a ready supplier mapped card in the Purchasing lane": function(e, board, sync_sales_order) {
							assert.isEmpty(board.backoffice)
							assert.isEmpty(board.sales)
							var header = sync_sales_order.DataArea.SalesOrder.SalesOrderHeader
							assert.deepEqual(board.purchasing, [{
								id: 'Source SO#'+header.DocumentID.ID,
								desc: '<br>'+header.CustomerParty.Name+'<br><em>suppliers mapped</em>',
								ready: true
							}])
							assert.isEmpty(board.done)
						},
						"\n    WHEN the Backoffice user asks for tasks": {
							topic: function(board, sync_sales_order) { var that = this
								current_role = 'backoffice'
								get('/tasks', function(e, res, tasks) {
									that.callback(e, tasks, sync_sales_order)
								})
							},
							"THEN he should get back a ProcessRFQ w a ProcessQuote attached": function(e, tasks, sync_sales_order) {
								assert.lengthOf(tasks, 1)
								assert.include(tasks[0], 'name')
								assert.equal(tasks[0].name, 'ProcessRFQ')
								assert.equal(tasks[0].ApplicationArea.Sender, 'backoffice')
								assert.equal(tasks[0].ApplicationArea.Receiver, 'supplier')
								assert.include(tasks[0].DataArea, 'RFQ')

								// assert.BOD(tasks[0].ProcessQuote, 'Process', 'Quote', 'backoffice', 'sales')
								assert.include(tasks[0], 'ProcessQuote')
								var pq = tasks[0].ProcessQuote
								assert.include(pq.DataArea, 'Quote')
								assert.equal(pq.name, 'ProcessQuote')
								assert.equal(pq.ApplicationArea.Sender, 'backoffice')
								assert.equal(pq.ApplicationArea.Receiver, 'sales')
							},
							"AND the ProcessRFQ's addressee should be the 1st supplier": function(e, tasks, sync_sales_order) {
								var party = tasks[0].DataArea.RFQ.RFQHeader.SupplierParty
								var suppliers = sync_sales_order.DataArea.SupplierPartyMaster
								var orig_party = suppliers[party.PartyIDs.ID[0]]
								assert.deepEqual(party, orig_party)
							},
							"AND the ProcessRFQ's items should be the same as the mapping": function(e, tasks, sync_sales_order) {
								var items = tasks[0].DataArea.RFQ.RFQLine
								var orig_items = sync_sales_order.DataArea.SalesOrder.SalesOrderLine
								assert.lengthOf(items, 2)
								assert.equal(items[0].Description, orig_items[0].Description)
								assert.equal(items[1].Description, orig_items[1].Description)
							},
							"\n    WHEN we have a look at the board": {
								topic: function(prev_tasks, sync_sales_order) { var that = this
									get('/board', function(e,r,board) { that.callback(e, prev_tasks, board, sync_sales_order) })
								},
								"THEN we should see a WIP sourcing card in the Backoffice lane": function(e, prev_tasks, board, sync_sales_order) {
									var header = sync_sales_order.DataArea.SalesOrder.SalesOrderHeader
									assert.deepEqual(board.backoffice, [{
										id: 'Source SO#'+header.DocumentID.ID,
										desc: '<br>'+header.CustomerParty.Name+'<br><em>sourcing...</em>',
										ready: false
									}])
									assert.isEmpty(board.sales)
									assert.isEmpty(board.purchasing)
									assert.isEmpty(board.done)
								},
								"\n    WHEN the Backoffice user asks for tasks again": {
									topic: function(prev_tasks, board, sync_sales_order) { var that = this
										current_role = 'backoffice'
										// clear the previous task by setting the same role
										post('/set_role', {role: current_role}, function(e, res, msg) {
											get('/tasks', function(e, res, tasks) {
												that.callback(e, tasks, prev_tasks[0], sync_sales_order)
											})
										})
									},
									"THEN he should get back a ProcessRFQ w a ProcessQuote attached": function(e, tasks, prfq1, sync_sales_order) {
										assert.lengthOf(tasks, 1)
										assert.include(tasks[0], 'name')
										assert.equal(tasks[0].name, 'ProcessRFQ')
										assert.equal(tasks[0].ApplicationArea.Sender, 'backoffice')
										assert.equal(tasks[0].ApplicationArea.Receiver, 'supplier')
										assert.include(tasks[0].DataArea, 'RFQ')
		
										// assert.BOD(tasks[0].ProcessQuote, 'Process', 'Quote', 'backoffice', 'sales')
										assert.include(tasks[0], 'ProcessQuote')
										var pq = tasks[0].ProcessQuote
										assert.include(pq.DataArea, 'Quote')
										assert.equal(pq.name, 'ProcessQuote')
										assert.equal(pq.ApplicationArea.Sender, 'backoffice')
										assert.equal(pq.ApplicationArea.Receiver, 'sales')
									},
									"AND the ProcessRFQ's addressee should be the 2nd supplier": function(e, tasks, prfq1, sync_sales_order) {
										var party = tasks[0].DataArea.RFQ.RFQHeader.SupplierParty
										var suppliers = sync_sales_order.DataArea.SupplierPartyMaster
										var supplier_id = sync_sales_order.DataArea.SalesOrder.SalesOrderLine[2].UserArea.SupplierID
										assert.equal(party.PartyIDs.ID[0], supplier_id)
										var orig_party = suppliers[supplier_id]
										assert.deepEqual(party, orig_party)
									},
									"AND the ProcessRFQ's items should be the same as the mapping": function(e, tasks, prfq1, sync_sales_order) {
										var items = tasks[0].DataArea.RFQ.RFQLine
										var orig_items = sync_sales_order.DataArea.SalesOrder.SalesOrderLine
										var rest = orig_items.length - 2
										assert.lengthOf(items, rest)
										for (var i = 0; i < rest; i++) {
											assert.equal(items[i].Description, orig_items[i + 2].Description)
										}
									},
									"\n    WHEN we have a look at the board": {
										topic: function(tasks, prfq1, sso) { var that = this
											get('/board', function(e,r,board) { that.callback(e, board, tasks, prfq1, sso) })
										},
										"THEN we should still see the WIP sourcing card in the Backoffice lane": function(e, board, tasks, prfq1, sso) {
											var header = sso.DataArea.SalesOrder.SalesOrderHeader
											assert.deepEqual(board.backoffice, [{
												id: 'Source SO#'+header.DocumentID.ID,
												desc: '<br>'+header.CustomerParty.Name+'<br><em>sourcing...</em>',
												ready: false
											}])
											assert.isEmpty(board.sales)
											assert.isEmpty(board.purchasing)
											assert.isEmpty(board.done)
										},
										"\n    WHEN he submits a Quote for the 1st RFQ": incoming_quote()
									}
								}
							}
						}
					}
				}
			}
		}
	}
})
function incoming_quote(){ return {
	topic: function(board, tasks, prfq1, sso){ var that = this
	  var prfq2 = tasks[0]
		var pq1 = prfq1.ProcessQuote
		pq1.DataArea.Quote.QuoteLine.forEach(function(item, idx) {
			item.UnitPrice.Amount = 10 + idx
		})
		current_role = 'backoffice'
		post('/sales', pq1, function(e, res, body) {that.callback(e, body, pq1, prfq1, prfq2, sso)})
	},
	"THEN he should get a confirmation": function(e, body, pq1, prfq1, prfq2, sso) {
		assert.isObject(body); assert.equal(body.status, "ok")
	},
	"\n    WHEN we have a look at the board": {
		topic: function(body, pq1, prfq1, prfq2, sso) { var that = this
			get('/board', function(e,r,board) { that.callback(e, board, body, pq1, prfq1, prfq2, sso) })
		},
		"THEN we should see a ready sourcing card in the Backoffice lane": function(e, board, body, pq1, prfq1, prfq2, sso) {
			var pq1Header = pq1.DataArea.Quote.QuoteHeader
			var header = sso.DataArea.SalesOrder.SalesOrderHeader
			assert.deepEqual(board.backoffice, [{
				id: 'Quote SO#'+header.DocumentID.ID,
				desc: '<br>'+pq1Header.SupplierParty.Name+'<br><em>quote received</em>',
				ready: true
			}])
			assert.isEmpty(board.sales)
			assert.isEmpty(board.purchasing)
			assert.isEmpty(board.done)
		},
		"\n    WHEN a Sales man asks for tasks": {
			topic: function(board, body, pq1, prfq1, prfq2, sso) { var that = this
				current_role = 'sales'
				get('/tasks', function(e, res, tasks) { that.callback(e, tasks, pq1, prfq1, prfq2, sso) })
			},
			"THEN he should not get any tasks yet": function(e, tasks, pq1, prfq1, prfq2, sso) {
				assert.isEmpty(tasks)
			},
			"\n    WHEN the Backoffice user submits a Quote for the 2nd RFQ": {
				topic: function(tasks, pq1, prfq1, prfq2, sso){ var that = this
					var pq2 = prfq2.ProcessQuote
					pq2.DataArea.Quote.QuoteLine.forEach(function(item, idx) {
						item.UnitPrice.Amount = 20 + idx
					})
					current_role = 'backoffice'
					post('/sales', pq2, function(e, res, body) {that.callback(e, body, pq1, pq2, prfq1, prfq2, sso)})
				},
				"THEN he should get a confirmation": function(e, body, pq1, pq2, prfq1, prfq2, sso) {
					assert.isObject(body); assert.equal(body.status, "ok")
				},
				"\n    WHEN we have a look at the board": {
					topic: function(body, pq1, pq2, prfq1, prfq2, sso) { var that = this
						get('/board', function(e,r,board) { that.callback(e, board, body, pq1, pq2, prfq1, prfq2, sso) })
					},
					"THEN we should see two ready sourcing card in the Backoffice lane": function(e, board, body, pq1, pq2, prfq1, prfq2, sso) {
						var pq1Header = pq1.DataArea.Quote.QuoteHeader
						var pq2Header = pq2.DataArea.Quote.QuoteHeader
						var header = sso.DataArea.SalesOrder.SalesOrderHeader
						assert.deepEqual(board.backoffice, [{
							id: 'Quote SO#'+header.DocumentID.ID,
							desc: '<br>'+pq1Header.SupplierParty.Name+'<br><em>quote received</em>',
							ready: true
						},{
							id: 'Quote SO#'+header.DocumentID.ID,
							desc: '<br>'+pq2Header.SupplierParty.Name+'<br><em>quote received</em>',
							ready: true
						}])
						assert.isEmpty(board.sales)
						assert.isEmpty(board.purchasing)
						assert.isEmpty(board.done)
					},
					"\n    WHEN a Sales man asks for tasks": {
						topic: function(board, body, pq1, pq2, prfq1, prfq2, sso) { var that = this
							current_role = 'sales'
							get('/tasks', function(e, res, tasks) { that.callback(e, tasks, pq1, pq2, prfq1, prfq2, sso) })
						},
						"THEN he should get a SyncSalesOrder for finalizing the Quote":
						function(e, tasks, pq1, pq2, prfq1, prfq2, sso) {
							assert.lengthOf(tasks, 1)
							var quote = tasks[0]
							assert.equal(quote.name, 'SyncSalesOrder')
							assert.equal(quote.ApplicationArea.Sender, 'sales')
							assert.equal(quote.ApplicationArea.Receiver, 'sales')
						},
						"WITH prices for the inventory mapped items": function(e, tasks, pq1, pq2, prfq1, prfq2, sso) {
							// the 1st item was mapped to an inventory item. the price should be the inventory item's price
							var items = tasks[0].DataArea.SalesOrder.SalesOrderLine
							assert.isNotEmpty(items)
							assert.isNotNull(items[0].CatalogReference.ItemID[0].ID)
							// hmm, we don't have the original SalesOrder with the inventory, so we cannot compare the price
							assert.isNotEmpty(items[0].UnitPrice.Amount)
						},
						"WITH prices from the 1st supplier Quote": function(e, tasks, pq1, pq2, prfq1, prfq2, sso) {
							// 2nd and 3rd items mapped to the first supplier
							var SOL = tasks[0].DataArea.SalesOrder.SalesOrderLine
							var QL = pq1.DataArea.Quote.QuoteLine
							assert.equal(QL[0].UnitPrice.Amount,
								getLine(SOL, QL[0].DocumentReference.SalesOrderReference.LineNumber).UnitPrice.Amount)
							assert.equal(QL[1].UnitPrice.Amount,
								getLine(SOL, QL[1].DocumentReference.SalesOrderReference.LineNumber).UnitPrice.Amount)
						},
						"WITH prices from the 2nd supplier Quote": function(e, tasks, pq1, pq2, prfq1, prfq2, sso) {
							var SOL = tasks[0].DataArea.SalesOrder.SalesOrderLine
							var QL = pq2.DataArea.Quote.QuoteLine
							assert.equal(QL[0].UnitPrice.Amount,
								getLine(SOL, QL[0].DocumentReference.SalesOrderReference.LineNumber).UnitPrice.Amount)
							assert.equal(QL[1].UnitPrice.Amount,
								getLine(SOL, QL[1].DocumentReference.SalesOrderReference.LineNumber).UnitPrice.Amount)
							assert.equal(QL[2].UnitPrice.Amount,
								getLine(SOL, QL[2].DocumentReference.SalesOrderReference.LineNumber).UnitPrice.Amount)
						},
						"\n    WHEN we have a look at the board": {
							topic: function(tasks, pq1, pq2, prfq1, prfq2, sso) { var that = this
								get('/board', function(e,r,board) { that.callback(e, board, tasks, pq1, pq2, prfq1, prfq2, sso) })
							},
							"THEN we should see a WIP quoting card in the Sales lane": function(e, board, tasks, pq1, pq2, prfq1, prfq2, sso) {
								var header = sso.DataArea.SalesOrder.SalesOrderHeader
								assert.isEmpty(board.backoffice)
								assert.deepEqual(board.sales, [{
									id: 'RFQ#V-1009',
									desc: '<br>'+header.CustomerParty.Name+'<br><em>quoting...</em>',
									ready: false
								}])
								assert.isEmpty(board.purchasing)
								assert.isEmpty(board.done)
							},
							"\n    WHEN he submits the Quote": {
								topic: function(board, tasks, pq1, pq2, prfq1, prfq2, sso){ var that = this
									var quote = tasks[0]
									post('/sales', quote, function(e, res, body) {that.callback(e, body, quote)})
								},
								"THEN he should get a confirmation": function(e, body, quote) {
									assert.isObject(body); assert.equal(body.status, "ok")
								},
								"\n    WHEN we have a look at the board": {
									topic: function(body, quote) { var that = this
										get('/board', function(e,r,board) { that.callback(e, board, body, quote) })
									},
									"THEN we should see a ready quoting card in the Sales lane": function(e, board, body, quote) {
										var header = quote.DataArea.SalesOrder.SalesOrderHeader
										assert.isEmpty(board.backoffice)
										assert.deepEqual(board.sales, [{
											id: 'RFQ#V-1009',
											desc: '<br>'+header.CustomerParty.Name+'<br><em>quoted</em>',
											ready: true
										}])
										assert.isEmpty(board.purchasing)
										assert.isEmpty(board.done)
									},
									"\n    WHEN the Backoffice user asks for tasks": {
										topic: function(board, body, quote) { var that = this
											current_role = 'backoffice'
											get('/tasks', function(e, res, tasks) {
												that.callback(e, tasks, quote)
											})
										},
										"THEN he should get back a ProcessQuote": function(e, tasks, quote) {
											assert.lengthOf(tasks, 1)
											assert.include(tasks[0], 'name')
											assert.equal(tasks[0].name, 'ProcessQuote')
											assert.equal(tasks[0].ApplicationArea.Sender, 'backoffice')
											assert.equal(tasks[0].ApplicationArea.Receiver, 'customer')
											assert.include(tasks[0].DataArea, 'Quote')
										},
										"WITH the same items as the Quote": function(e, tasks, quote) {
											var pq_items = tasks[0].DataArea.Quote.QuoteLine
											var q_items = quote.DataArea.SalesOrder.SalesOrderLine
											assert.lengthOf(pq_items, q_items.length)
											pq_items.forEach(function(pq_item, idx){
												assert.equal(pq_item.UnitPrice.Amount, q_items[idx].UnitPrice.Amount)
											})
										},
										"AND the addressee is the sender of the original RFQ": function(e, tasks, sso) {
											var pq = tasks[0]
											assert.deepEqual(pq.DataArea.Quote.QuoteHeader.CustomerParty,
												sso.DataArea.SalesOrder.SalesOrderHeader.CustomerParty)
											assert.deepEqual(pq.DataArea.Quote.QuoteHeader.SupplierParty,
												ourselves)
										},
										"\n    WHEN we have a look at the board": {
											topic: function(tasks, sso) { var that = this
												get('/board', function(e,r,board) { that.callback(e, board, tasks, sso) })
											},
											"THEN we should see a WIP quote sending card in the Backoffice lane": function(e, board, tasks, sso) {
												var header = sso.DataArea.SalesOrder.SalesOrderHeader
												assert.deepEqual(board.backoffice, [{
													id: 'RFQ#V-1009',
													desc: '<br>'+header.CustomerParty.Name+'<br><em>sending quote...</em>',
													ready: false
												}])
												assert.isEmpty(board.sales)
												assert.isEmpty(board.purchasing)
												assert.isEmpty(board.done)
											},
											"\n    WHEN he submits the Quote": {
												topic: function(board, tasks, sso){ var that = this
													var quote = tasks[0]
													post('/sales', quote, function(e, res, body) {that.callback(e, body, quote)})
												},
												"THEN he should get a confirmation": function(e, body, quote) {
													assert.isObject(body); assert.equal(body.status, "ok")
												},
												"\n    WHEN we have a look at the board": {
													topic: function(body, quote) { var that = this
														get('/board', function(e,r,board) { that.callback(e, board, quote) })
													},
													"THEN we should see a ready quote sending card in the Backoffice lane": function(e, board, quote) {
														var header = quote.DataArea.Quote.QuoteHeader
														assert.deepEqual(board.backoffice, [{
															id: 'RFQ#V-1009',
															desc: '<br>'+header.CustomerParty.Name+'<br><em>quote sent</em>',
															ready: true
														}])
														assert.isEmpty(board.sales)
														assert.isEmpty(board.purchasing)
														assert.isEmpty(board.done)
													}
												}
											}
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}
}}

exports.visitor = vows.describe(
'Visitor\n\
	As a visitor\n\
	I should have limited access\n\
	So I can\'t get to know company secrets or interfere with operations',
{
	"": {
		topic: function() { cookies = {}; current_role = ''; return true },
		"WHEN I try to get tasks": {
			topic: function() { get('/tasks', this.callback) },
			"THEN I should be unauthorized": unauthorized
		},
		"WHEN I try to send messages to Sales": {
			topic: function() { post('/sales', {}, this.callback) },
			"THEN I should be unauthorized": unauthorized
		}
	}
})

exports.login = vows.describe(
'Login\n\
	As a registered user\n\
	I should be prove my identity to the system\n\
	So my further actions can be associated with me',
{
	"": {
		topic: function() { var that = this; cookies = {}; current_role = ''
			post("/init_db", {}, function() { post("/restart", {}, that.callback) })
		},
		"GIVEN I am a registered user": register('buyer')
	}
},
{
	"WHEN I get /current_user": {
		topic: function() { get('/current_user', this.callback) },
		"THEN I should not be found": not_found
	}
},
{
	"WHEN I try to login with wrong password": {
		topic: function() {
			var user = {email: users.buyer.email, password: "x"+users.buyer.password}
			post('/login', user, this.callback)
		},
		"THEN I should be unauthorized": unauthorized
	},
	"WHEN I try to login with wrong email address": {
		topic: function() {
			var user = {email: "x"+users.buyer.email, password: users.buyer.password}
			post('/login', user, this.callback)
		},
		"THEN I should be unauthorized": unauthorized
	}
},
{
	"WHEN I login AND get /current_user": {
		topic: function() { var that = this
			var user = {email: users.buyer.email, password: users.buyer.password}
			post('/login', user, function(e, res, body) {
				current_session_is('buyer', res)
				current_role = 'buyer'
				get('/current_user', function(e, res, body) { that.callback(e, body, user) })
			})
		},
		"THEN I should be recognized": function(e, body, user) {
			assert.equal(body.email, user.email)
		}
	}
},
{
	"WHEN I logout": {
		topic: function() { var that = this
			post('/logout', {}, function() { get('/current_user', that.callback) })
		},
		"THEN I should not be found": not_found
	}
}
)  // describe login
