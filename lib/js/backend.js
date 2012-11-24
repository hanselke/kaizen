var utils = require('./modules/utils'); utils.init(Object)
var matcher = require('./matcher'); matcher.init(Object)
var oagis = require('./oagis')
var request = require('request')
var inventory = require('./inventory').inventory
var suppliers = require('./suppliers').list
var ourselves = require('./ourselves').party
var fs = require('fs')
var CAS = require('cas');
var cas = new CAS({base_url: 'https://ec2-54-251-64-194.ap-southeast-1.compute.amazonaws.com:8000/app', service: 'my_service'});

var repl = require('repl')
repl = repl.start('node in backend> ')
init_repl()

function init_repl() {
	repl.context.utils = utils
	repl.context.oagis = oagis
	repl.context.request = request
	repl.context.inventory = inventory
	repl.context.suppliers = suppliers
	repl.context.ourselves = ourselves
	repl.context.loadDB = loadDB
	repl.context.saveDB = saveDB
	repl.context.getBOD = getBOD
	repl.context.getSO = getSO
	repl.context.getRef = getRef
	repl.context.matcher = matcher.matcher
	repl.context.dump = dump

	repl.context.BODs = BODs
	repl.context.WIP = WIP
	repl.context.Q = Q
	repl.context.users = users
	repl.context.latest_SOID = latest_SOID
	repl.context.SOs = SOs
}

var BODs, WIP, Q, users, latest_SOID, SOs

var database_dir = '/non/existant' // initialized in set_db_dir()
var bods_dir
var sos_dir

exports.set_db_dir = function(db_dir) {
	database_dir = db_dir
	bods_dir = database_dir+'/BODs'
	sos_dir = database_dir+'/SOs'
	try { fs.mkdirSync(database_dir, 0755) } catch(e) {}
	try { fs.mkdirSync(bods_dir, 0755) } catch(e) {}
	try { fs.mkdirSync(sos_dir, 0755) } catch(e) {}
	loadDB()
}

exports.init_db = function() {
	BODs = {}
	WIP = {}
	Q = []
	latest_SOID = 1245
	SOs = {}
	exports.users = users = {
  "andras@openbusiness.com.sg": {
    "company_name": "X",
    "id": 2,
    "password": "a",
    "roles": [
    	"backoffice",
      "sales",
      "purchasing"
    ],
    name: 'Andras',
    avatar: 'psmith',
    "email": "andras@openbusiness.com.sg"
  },
  "noroles@openbusiness.com.sg": {
    "company_name": "GUAN-HUAT",
    "id": "noroles",
    "password": "x",
    "email": "noroles@openbusiness.com.sg"
  },
  "sales@openbusiness.com.sg": {
    "company_name": "GUAN-HUAT",
    "id": "sales",
    "password": "sales",
    "roles": [
      "sales"
    ],
    "email": "sales@openbusiness.com.sg"
  },
  "hanselke@openbusiness.com.sg": {
    "company_name": "openbiz",
    "id": 3,
    "password": "demo",
    "roles": [
    	"backoffice",
      "sales",
      "purchasing"
    ],
    name: 'Hansel Ke',
    avatar: 'hansel',
    "email": "hanselke@openbusiness.com.sg"
  },
  "onetom@openbusiness.com.sg": {
    "company_name": "Open Business",
    "id": 4,
    "password": "x",
    "roles": [
    	"backoffice",
      "sales",
      "purchasing"
    ],
    name: 'Tom',
    avatar: 'onetom',
    "email": "onetom@openbusiness.com.sg"
  }
	}
	exports.set_db_dir(database_dir) // it is needed to create directories in the db-test dir
	saveDB()
	init_repl()
}

function dumpWIP(msg) {
	console.log('========= WIP '+msg+':')
	Object.keys(WIP).forEach(function(bodid){
		console.log('==', getBOD(bodid) ? getBOD(bodid).name : 'unknown bod: '+bodid, WIP[bodid])
	})
}

function dump(value) {
	console.log(rdump(value, ''))
}
function rdump(value, indent) {
	if (value && value.LineNumber && value.Description) { //Line item
		var s = value.LineNumber + '\t' +
				value.Quantity + '\t' +
				value.Description + '\t' +
				(value.UnitPrice ? value.UnitPrice.Amount : 'undefined') + '\t'
		if (value.CatalogReference && value.CatalogReference.ItemID[0].ID) {
			s += 'mapped to inventory item: ' + value.CatalogReference.ItemID[0].ID
		} else if (value.UserArea && value.UserArea.SupplierID) {
			s += 'mapped to supplier: ' + value.UserArea.SupplierID
		} else {
			s += 'not mapped'
		}
		return s
	} else if (value && typeof(value) == 'object' && value.length !== undefined) { //array
		if (value.length == 0) return '[]'
		var ind = indent + '  '
		if (value.length == 1) {
			var s = rdump(value[0], ind)
			if (s.length < 40) return '[ ' + s + ' ]'
		}

		var s = '[ //size: ' + value.length + '\n'
		for (var i in value){
			s += ind + rdump(value[i], ind) + (i < value.length - 1 ? ',' : '') + '\n'
		}
		s += indent + ']'
		return s
	} else if (value && typeof(value) == 'object') { //object
		var keys = Object.keys(value)
		var s = '{ //keys: ' + keys.length + '\n'
		var ind = indent + '  '
		for (var i in keys) {
			s += ind + keys[i] + ': ' + rdump(value[keys[i]], ind) + (i < keys.length - 1 ? ',' : '') + '\n'
		}
		s += indent + '}'
		return s
	}
	return JSON.stringify(value, null, '\t')
}

function saveFile(fn, content) {
	console.log('writing file '+fn)
	fs.writeFileSync(fn, JSON.stringify(content, null, '\t'))
}
function readFile(fn) {
	console.log('reading file '+fn)
	try {
		return JSON.parse(fs.readFileSync(fn))
	} catch(e) {
		//TODO handle errors properly
		console.log(e)
		return undefined
	}
}
function saveBOD(bod) {
	bod = bod.deepCopy()
	BODs[bod.ApplicationArea.BODID] = bod
	var fn = bods_dir + '/' + bod.ApplicationArea.BODID
	saveFile(fn, bod)
}
function getBOD(bodid) {
	if (!BODs[bodid]) {
		BODs[bodid] = readFile(bods_dir + '/' + bodid)
	}
	return BODs[bodid]
}
function saveSO(so) {
	SOs[so.SalesOrderHeader.DocumentID.ID] = so
	var fn = sos_dir + '/' + so.SalesOrderHeader.DocumentID.ID
	saveFile(fn, so)
}
function getSO(soid) {
	if (!SOs[soid]) {
		SOs[soid] = readFile(sos_dir + '/' + soid)
	}
	return SOs[soid]
}
function saveDB() {
	var db = {
		WIP: WIP,
		Q: Q,
		users: users,
		latest_SOID: latest_SOID
	}
	var fn = database_dir + '/small_objects'
	saveFile(fn, db)
}
function loadDB() {
	var fn = database_dir + '/small_objects'
	var db = readFile(fn)
	if (db) {
		WIP = db.WIP
		Q = db.Q
		exports.users = users = db.users
		latest_SOID = db.latest_SOID
		BODs = BODs || {} // need to initialize in production mode
		SOs = SOs || {} // need to initialize in production mode
	}
	init_repl()
}

function getRef(bod) {
	var refHeader, data = bod.DataArea
	switch (bod.name) {
		case 'ProcessFax': return bod.ApplicationArea.BODID
		case 'ProcessRFQ': refHeader = data.RFQ.length ? data.RFQ[0].RFQHeader : data.RFQ.RFQHeader; break
		case 'ProcessSalesOrder':
		case 'SyncSalesOrder': refHeader = data.SalesOrder.SalesOrderHeader; break
		case 'ProcessQuote': refHeader = data.Quote.QuoteHeader; break
		case 'ProcessPurchaseOrder': refHeader = data.PurchaseOrder.PurchaseOrderHeader; break
	}
	console.log('---- getRef: bod.name:', bod.name)
	var ret = refHeader.DocumentReference.DocumentID.ID
	console.log('---- ret:', ret)
	return ret
}
exports.create_task = function(req, res) {
	var bod = req.body
	if (bod.name == 'SyncSalesOrder' && bod.ApplicationArea.Sender == 'purchasing') {
		var err = validate_Sync_supplier_mapped_SalesOrder(bod)
		if (err) return res.send(err, 400)
	}
	var handlers = {
		ProcessRFQ: create_ProcessRFQ,
		ProcessSalesOrder: create_ProcessSalesOrder,
		SyncSalesOrder: create_SyncSalesOrder,
		ProcessQuote: create_ProcessQuote,
		ProcessPurchaseOrder: create_ProcessPurchaseOrder
	}
	if (handlers[bod.name]) {
		bod.ApplicationArea.BODID = utils.generateUUID()
		bod.ApplicationArea.CreationDateTime = new Date()
		saveBOD(bod)
		delete WIP[getRef(bod)]
		WIP[bod.ApplicationArea.BODID] = {lane: bod.ApplicationArea.Sender, WIP: false}
		saveDB()
		req.current_user.latest_task = undefined
		handlers[bod.name](bod, res)
	} else
		throw 'Exception: POST /sales got unknown BOD'
}

exports.tasks = function(req, res) {
	var idx = parseInt(req.params.idx) || null
	if ((idx == null) && req.current_user.latest_task)
		return res.send( [req.current_user.latest_task] )
	var roles = ['sales','backoffice','billing','warehouse','purchasing'] //req.current_user.roles
	console.log('roles: ', roles)
	console.log(Q)
	for (var i in Q) {
		var bod = Q[i]
		if (roles.indexOf(bod.ApplicationArea.Sender) >= 0) {
			if (idx == null) {
				Q.splice(i, 1)
				req.current_user.latest_task = bod
			} else if (--idx) continue
			var ref = getRef(bod)
			var refBOD = getBOD(ref)
			if (!ref) throw new Error('No reference in bod: '+JSON.stringify(bod))
			// if the Sales gets the quoting task
			if (bod.name == 'SyncSalesOrder' &&
					bod.ApplicationArea.Sender == 'sales' &&
					refBOD.name == 'ProcessRFQ') {
				// need to remove all referenced documents from WIP
				var SOID = bod.DataArea.SalesOrder.SalesOrderHeader.DocumentID.ID
				for (var id in WIP) {
					var b = getBOD(id)
					if (b.name == 'ProcessQuote' &&
							b.DataArea.Quote.QuoteHeader.DocumentReference.SalesOrderReference &&
							b.DataArea.Quote.QuoteHeader.DocumentReference.SalesOrderReference.DocumentID.ID == SOID) {
						delete WIP[id]
					}
				}
				// add a status to the ProcessRFQ, so we'll know in the board function that
				// a different label should be displayed
				refBOD.ApplicationArea.extend({
					UserArea: {status: 'quoting'}
				})
				saveBOD(refBOD)
			}
			WIP[ref] = {lane: bod.ApplicationArea.Sender, WIP: true}
			saveDB()
			return res.send( [bod] )
		}
	}
	res.send([])
}

exports.quotes = function(req, res) {
	var quotes = []
	for (bod_id in BODs) {
		var bod = BODs[bod_id]
		if (bod.name == 'ProcessQuote' &&
			bod.ApplicationArea.Sender == 'backoffice' &&
			bod.ApplicationArea.Receiver == 'customer') {
			quotes.push(bod.DataArea.Quote)
		}
	}
	res.send(quotes)
}

exports.create_user = function(req, res) {
	if (req.current_user) return res.send({msg: "Registration not allowed", status: "error"}, 403)
	var details = req.body
	delete details.password2
	if (users[details.email]) res.send({msg: "Already registered", status: "error"}, 409)
	else {
		users[details.email] = details.deepCopy()
		delete details.password
		details.id = 1
		res.send(details)
	}
}

exports.current_user = function(req, res) {
  req.current_user ? res.send(req.current_user) : res.send({}, 404)
}

exports.login = function(req, res) {
	var cred = req.body
	var user = users[cred.email]
	if (user && user.password == cred.password) {
		req.session.current_user_id = cred.email
		res.send({})
	} else {
		res.send({msg: "Invalid credentials", status: "error"}, 401)
	}
}

exports.cas_login = function(req, res) {
  var ticket = req.param('ticket');
  if (ticket) {
    cas.validate(ticket, function(err, status, username) {
      if (err) {
        // Handle the error
        res.send({error: err});
      } else {
        // Log the user in
        res.send({status: status, username: username});
      }
    });
  } else {
    res.redirect('/');
  }
};



exports.logout = function(req, res) {
	req.session.destroy()
	res.send({})
}

exports.create_fax = function(req, res) {
// curl -D- -H 'Content-Type: application/json' http://localhost:8001/faxes -d '{"image": "RFQ"}'
	var fax = req.body
	process_fax = ProcessFax(fax, req.app.settings.env == 'development')
	saveBOD(process_fax)
	Q.push(process_fax)
	saveDB()
	res.send({})
}

function ProcessFax(fax, demo) {
	var demoCustomerParty = {"AccountID":null,"Contact":{"Communication":{"UserArea":{"Email":"","Fax":"67858972","Phone":"67858970"}},"Name":null},"CustomerAccountID":null,"Location":{"Address":{"AddressLine":["Blk 9012, Tampines St 93, #03-217",""],"AttentionOfName":null,"CityName":null,"CountryCode":"SG","PostalCode":"528845","ID":[]},"ID":null},"Name":"Sophie supply & Services Company","PartyIDs":{"ID":[]}}
	
	var demoRFQLine = [{"Description":"Pipe Plug Hex, Black, Forged Steel NPT 3000# 3/4\"","LineNumber":1,"Quantity":"12","Quantity_unitCode":null},{"Description":"Pipe Union, Black, Forged Steel, NPT 2\" 300#","LineNumber":2,"Quantity":"2","Quantity_unitCode":null},{"Description":"Gate Valve, Full port, 2\" NPT Female, Brass 200PSI","LineNumber":3,"Quantity":"1","Quantity_unitCode":null},{"Description":"Reducing Bushing Pipe, Black, Forged Steel, 1-1/2\" NPTM X 3/4\" NPTF 3000#","LineNumber":4,"Quantity":"4","Quantity_unitCode":null},{"Description":"Ball Valve 2\" Female NPT 600 WOG 150PSI Bronze/Brass","LineNumber":5,"Quantity":"2","Quantity_unitCode":null},{"Description":"Pipe Tee, Black, 1/2\" NPT 3000#","LineNumber":6,"Quantity":"1","Quantity_unitCode":null}]
	
	var ProcessRFQ = oagis.ProcessRFQ.deepCopy()
	ProcessRFQ.ApplicationArea.Sender = 'backoffice'
	ProcessRFQ.ApplicationArea.Receiver = 'sales'
	var ProcessPurchaseOrder = oagis.ProcessPurchaseOrder.deepCopy()
	ProcessPurchaseOrder.ApplicationArea.Sender = 'backoffice'
	ProcessPurchaseOrder.ApplicationArea.Receiver = 'sales'
	var res = {
		name: "ProcessFax",
		ApplicationArea: {Sender: 'backoffice'},
		image: fax.image,
		task_id: fax.task_id,
		ProcessRFQ: ProcessRFQ,
		ProcessQuote: {},
		ProcessPurchaseOrder: ProcessPurchaseOrder
	}
	res.ApplicationArea.BODID = utils.generateUUID()
	res.ProcessRFQ.DataArea.RFQ.RFQHeader.DocumentReference.DocumentID.ID = res.ApplicationArea.BODID
	res.ProcessPurchaseOrder.DataArea.PurchaseOrder.PurchaseOrderHeader.DocumentReference.DocumentID.ID = res.ApplicationArea.BODID
	if (demo) {
		res.demoProcessRFQ = ProcessRFQ.deepCopy()
		var demoRFQ = res.demoProcessRFQ.DataArea.RFQ
		demoRFQ.RFQHeader.DocumentID = {ID: 'V-1009'}
		demoRFQ.RFQHeader.CustomerParty = demoCustomerParty
		demoRFQ.RFQLine = demoRFQLine

		res.demoProcessPurchaseOrder = ProcessPurchaseOrder.deepCopy()
		var demoPO = res.demoProcessPurchaseOrder.DataArea.PurchaseOrder
		demoPO.PurchaseOrderHeader.CustomerParty = demoCustomerParty
		demoPO.PurchaseOrderLine = demoRFQLine
	}
	return res
}


var create_ProcessRFQ = function(bod, res) {
	Q.push(ProcessRFQ(bod))
	saveDB()
	res.send({status: "ok"});
}

var ProcessRFQ = function (ProcessRFQ, $ts) {
	var RFQ = ProcessRFQ.DataArea.RFQ
	var ProcessSalesOrder = oagis.ProcessSalesOrder.deepCopy()
	ProcessSalesOrder.ApplicationArea.Receiver = 'sales'
	ProcessSalesOrder.ApplicationArea.Sender = 'sales'
	ProcessSalesOrder.DataArea.SalesOrder.SalesOrderHeader.extend({
		DocumentReference: {DocumentID: {ID: ProcessRFQ.ApplicationArea.BODID}},
		CustomerParty: RFQ.RFQHeader.CustomerParty
	})
	RFQ.RFQLine.forEach( function(line,index,arr){
		ProcessSalesOrder.DataArea.SalesOrder.SalesOrderLine.push({
			LineNumber: line.LineNumber,
			Description: line.Description,
			Quantity: line.Quantity,
			Quantity_unitCode: line.Quantity_unitCode,

			CatalogReference: {ItemID: [{ID: null}]},
			UnitPrice: {
				Amount: null,
				Amount_currencyID: null,
				PerQuantity: null,
				PerQuantity_unitCode: null
			},
			ExtendedAmount: null,
			ExtendedAmount_currencyID: null,
			TotalAmount: null,
			TotalAmount_currencyID: null
		})
	})
	ProcessSalesOrder.DataArea.PriceList = inventory
	return ProcessSalesOrder
}

function create_ProcessSalesOrder(bod, res) {
	if (bod.ApplicationArea.Sender == 'sales') {
		Q.push(ProcessSalesOrder(bod))
		saveDB()
		res.send({status: "ok"})
	} else
		res.send({status: "error", msg: 'Invalid ProcessSalesOrder'})
}

function ProcessSalesOrder(ProcessSalesOrder, $ts) {
	var items_to_forward = []
	var SyncSalesOrder = oagis.SyncSalesOrder.deepCopy()
	SyncSalesOrder.ApplicationArea.Sender = 'sales'
	SyncSalesOrder.ApplicationArea.Receiver = 'sales'
	var SO = SyncSalesOrder.DataArea.SalesOrder
	var SOID = ++latest_SOID
	ProcessSalesOrder.DataArea.SalesOrder.SalesOrderHeader.extend({
		DocumentID: {ID: SOID},
		CustomerParty: ProcessSalesOrder.DataArea.SalesOrder.SalesOrderHeader.CustomerParty,
		SupplierParty: ourselves.deepCopy()
	})
	SO.SalesOrderHeader = ProcessSalesOrder.DataArea.SalesOrder.SalesOrderHeader.deepCopy()
	SO.SalesOrderHeader.extend({
		DocumentReference: {DocumentID: {ID: ProcessSalesOrder.ApplicationArea.BODID}}
	})
	ProcessSalesOrder.DataArea.SalesOrder.SalesOrderLine.forEach(function(item) {
		var inventory_id = item.CatalogReference.ItemID[0].ID
		if (inventory_id) {
			item.UnitPrice.Amount = inventory.items[ inventory_id ].price
			SO.SalesOrderLine.push(item)
		} else {
			item.UserArea = {SupplierID: null}
			items_to_forward.push(item)
		}
	})
	saveSO(ProcessSalesOrder.DataArea.SalesOrder)
	if (items_to_forward.length) {
		SyncSalesOrder.ApplicationArea.Sender = 'purchasing'
		SyncSalesOrder.ApplicationArea.Receiver = 'sales'
		SyncSalesOrder.DataArea.SupplierPartyMaster = suppliers
		SyncSalesOrder.DataArea.SalesOrder.SalesOrderLine = items_to_forward
	}
	return SyncSalesOrder
}

function create_SyncSalesOrder(SyncSalesOrder, res) {
	if (SyncSalesOrder.ApplicationArea.Sender == 'purchasing') {
		Q = Q.concat(Sync_supplier_mapped_SalesOrder(SyncSalesOrder))
		init_repl()
		saveDB()
		res.send({status: "ok"})
	} else if (SyncSalesOrder.ApplicationArea.Sender == 'sales') {
		Q.push(Sync_quoted_SalesOrder(SyncSalesOrder))
		saveDB()
		res.send({status: "ok"})
	} else
		res.send({status: "error", msg: 'Invalid SyncSalesOrder'})
}

function validate_Sync_supplier_mapped_SalesOrder(SyncSalesOrder) {
	var newSO = SyncSalesOrder.DataArea.SalesOrder
	for (var i in newSO.SalesOrderLine) {
		if (!newSO.SalesOrderLine[i].UserArea.SupplierID)
			return {status: "error", msg: 'All items should be mapped to a supplier.'}
	}
}

function Sync_supplier_mapped_SalesOrder(SyncSalesOrder) {
	var ProcessRFQ = oagis.ProcessRFQ.deepCopy()
	var newSO = SyncSalesOrder.DataArea.SalesOrder
	var SOID = newSO.SalesOrderHeader.DocumentID.ID
	ProcessRFQ.ApplicationArea = { Sender: 'backoffice', Receiver: 'supplier' }
	ProcessRFQ.DataArea.RFQ.RFQHeader.extend({
		DocumentReference: {DocumentID: {ID: SyncSalesOrder.ApplicationArea.BODID}}
	})
	ProcessRFQ.ProcessQuote = oagis.ProcessQuote.deepCopy()
	ProcessRFQ.ProcessQuote.ApplicationArea = { Sender: 'backoffice', Receiver: 'sales' }
	ProcessRFQ.ProcessQuote.DataArea.Quote.QuoteHeader.extend({
		DocumentID: {ID: null},
		DocumentReference: {
			DocumentID: {ID: SyncSalesOrder.ApplicationArea.BODID},
			SalesOrderReference: { DocumentID: {ID: SOID} } }
	})
	var SO = getSO(SOID)
	newSO.SalesOrderLine.forEach(function(L) {
		getLine(SO.SalesOrderLine, L.LineNumber).UserArea = L.UserArea})
	saveSO(SO)
	var rfqs = {}
	newSO.SalesOrderLine.forEach(function(item) {
		var quote_item = oagis.QuoteLineType.deepCopy().extend(item)
		quote_item.DocumentReference.SalesOrderReference.LineNumber = item.LineNumber
		var rfq_item = oagis.RFQLineType.deepCopy().extend(item)
		rfq_item.DocumentReference.SalesOrderReference.LineNumber = item.LineNumber
		var supplier_id = item.UserArea.SupplierID
		var rfq = rfqs[supplier_id] || ProcessRFQ.deepCopy()
		rfqs[supplier_id] = rfq
		rfq_item.LineNumber = rfq.DataArea.RFQ.RFQLine.length + 1
		rfq.DataArea.RFQ.RFQHeader.SupplierParty = suppliers[supplier_id]
		rfq.DataArea.RFQ.RFQHeader.CustomerParty = ourselves
		rfq.DataArea.RFQ.RFQLine.push(rfq_item)
		quote_item.LineNumber = rfq.ProcessQuote.DataArea.Quote.QuoteLine.length + 1
		rfq.ProcessQuote.DataArea.Quote.QuoteHeader.SupplierParty = suppliers[supplier_id]
		rfq.ProcessQuote.DataArea.Quote.QuoteLine.push(quote_item)
	})
	var ProcessRFQs = []
	Object.keys(rfqs).forEach( function(supplierid){ ProcessRFQs.push(rfqs[supplierid]) } )
	return ProcessRFQs
}

function Sync_quoted_SalesOrder(SyncSalesOrder) {
	var ProcessQuote = oagis.ProcessQuote.deepCopy()
	ProcessQuote.ApplicationArea = { Sender: 'backoffice', Receiver: 'customer' }
	var SO = SyncSalesOrder.DataArea.SalesOrder
	var Quote = ProcessQuote.DataArea.Quote
	Quote.QuoteLine = SO.SalesOrderLine
	Quote.QuoteHeader = SO.SalesOrderHeader
	Quote.QuoteHeader.extend({
		DocumentReference: {DocumentID: {ID: SyncSalesOrder.ApplicationArea.BODID}}
	})
	return ProcessQuote
}

function create_ProcessQuote(ProcessQuote, res) {
	var ok = false, aa = ProcessQuote.ApplicationArea
	if (aa.Sender == 'backoffice') {
		if (aa.Receiver == 'customer') {
			Process_customer_Quote(ProcessQuote); ok = true
		} else if (aa.Receiver == 'sales') {
			Q = Q.concat(Process_supplier_Quote(ProcessQuote)); ok = true
			init_repl()
			saveDB()
		}
	}
	res.send( ok ? {status: "ok"} : {status: "error", msg: 'Invalid ProcessQuote'})
}

function Process_supplier_Quote(ProcessQuote) {
	var Quote = ProcessQuote.DataArea.Quote
	var SOID = Quote.QuoteHeader.DocumentReference.SalesOrderReference.DocumentID.ID
	var SO = getSO(SOID)
	Quote.QuoteLine.forEach( function(L) {
		getLine(SO.SalesOrderLine, L.DocumentReference.SalesOrderReference.LineNumber).UnitPrice = L.UnitPrice
	})
	if (SO.SalesOrderLine.map(function(L) {return !!L.UnitPrice.Amount}).indexOf(false) >= 0) return []
	var SSO = oagis.SyncSalesOrder.deepCopy()
	SSO.ApplicationArea = { Sender: 'sales', Receiver: 'sales' }
	SSO.DataArea.SalesOrder = SO.deepCopy()
	return [SSO]
}

function Process_customer_Quote(ProcessQuote) {
}

var create_ProcessPurchaseOrder = function(bod, res) {
	Q.push(ProcessPurchaseOrder(bod))
	saveDB()
	res.send({status: "ok"});
}

function ProcessPurchaseOrder(ProcessPurchaseOrder, $ts) {
	var PurchaseOrder = ProcessPurchaseOrder.DataArea.PurchaseOrder
	var soid = PurchaseOrder.PurchaseOrderHeader.DocumentReference.DocumentID.ID
	if (soid) { //if there is a Quote reference, then use that SO as a SyncSO
		var SSO = oagis.SyncSalesOrder.deepCopy()
		SSO.ApplicationArea = { Sender: 'sales', Receiver: 'sales' }
		SSO.DataArea.SalesOrder = getSO(soid).deepCopy()
		return SSO
	} else {
		var SSO = oagis.SyncSalesOrder.deepCopy()
		SSO.ApplicationArea = { Sender: 'sales', Receiver: 'sales' }
		var SO = oagis.SalesOrder.deepCopy()
		SO.SalesOrderHeader.extend(PurchaseOrder.PurchaseOrderHeader)
		SSO.DataArea.SalesOrder = SO
		//copy items from the referenced Quotes to the new SO
		for (var i in PurchaseOrder.PurchaseOrderLine) {
			var item = PurchaseOrder.PurchaseOrderLine[i]
			var soid = item.QuoteReference.DocumentID.ID
			if (soid && getSO(soid)) {
				var quote = getSO(soid).deepCopy()
				var lineno = item.QuoteReference.LineNumber
				var line = getLine(quote.SalesOrderLine, lineno)
				item.Description = line.Description //copy the description from the referenced Quote item
				SO.SalesOrderLine.push(item)
			}
		}
		//if all line items have a Quote reference, we are done
		if (SO.SalesOrderLine.length == PurchaseOrder.PurchaseOrderLine.length) {
			//TODO save SO?
			return SSO
		}
		//otherwise create a new SyncSO
	}
	throw "need tests for this case"
}

function getLine(lines, num) {
	for (var i in lines)
		if (lines[i].LineNumber == num) return lines[i]
	throw 'No item with LineNumber '+num+' amongst '+lines.map(function(L){return L.LineNumber})
}

exports.board = function(req, res) {
/*
FAX -> OB
Q = [ProcessFax]
WIP = []
Ready = [FAX]

OB -> next task
Q = []
WIP = [ProcessFax]
Ready = []

ProcessRFQ -> OB
Q = [Sync_mapped_SalesOrder]
WIP = []
Ready = [ProcessRFQ]

OB -> next task
Q = []
WIP = [Sync_mapped_SalesOrder]
Ready = []

Sync_mapped_SalesOrder -> OB
Q = [Sync_priced_SalesOrder]
WIP = []
Ready = [Sync_mapped_SalesOrder]

Q = []
WIP = []
Ready = []
*/
	var cards = {
		backoffice: [],
		sales: [],
		purchasing: [],
		done: []
	}
	for(var bodid in WIP) {
		var bod = getBOD(bodid)
		console.log('bodid:', bodid,'WIP[bodid]:', WIP[bodid])
		var card
		if (bod.name == 'ProcessFax') {
			card = {id: 'FAX', desc: 'processing...', ready: false}
		} else if (bod.name == 'ProcessRFQ') {
			var header = bod.DataArea.RFQ.RFQHeader
			var ready = !WIP[bodid].WIP
			if (bod.ApplicationArea.UserArea && bod.ApplicationArea.UserArea.status == 'quoting') {
				card = {id: "RFQ#"+header.DocumentID.ID,
					desc: '<br>'+header.CustomerParty.Name+(ready ? '' : '<br><em>quoting...</em>'), ready: ready}
			} else {
				card = {id: "RFQ#"+header.DocumentID.ID,
					desc: '<br>'+header.CustomerParty.Name+(ready ? '' : '<br>mapping inventory...'), ready: ready}
			}
		} else if (bod.name == 'ProcessSalesOrder') {
			var header = getBOD(getRef(bod)).DataArea.RFQ.RFQHeader
			var ready = !WIP[bodid].WIP
			card = ready
				? {
					id: "RFQ#"+header.DocumentID.ID,
					desc: '<br>'+header.CustomerParty.Name+'<br><em>inventory mapped</em>', ready: ready
					}
				:	{
					id: "RFQ#"+header.DocumentID.ID, //+' SO#'+bod.DataArea.SalesOrder.SalesOrderHeader.DocumentID.ID,
					desc: '<br>'+header.CustomerParty.Name+'<br><em>mapping suppliers...</em>', ready: ready
					}
		} else if (bod.name == 'SyncSalesOrder') {
			var ready = !WIP[bodid].WIP
			var refBOD = getBOD(getRef(bod))
			if (refBOD.ApplicationArea.UserArea && refBOD.ApplicationArea.UserArea.status == 'quoting') {
				var header = refBOD.DataArea.RFQ.RFQHeader
				var msg = (ready ? 'quoted' : 'sending quote...')
				card = {id: "RFQ#"+header.DocumentID.ID,
					desc: '<br>'+header.CustomerParty.Name+'<br><em>'+msg+'</em>', ready: ready}
			} else {
				var header = bod.DataArea.SalesOrder.SalesOrderHeader
				card = ready
					? {
						id: "Source SO#"+header.DocumentID.ID,
						desc: '<br>'+header.CustomerParty.Name+'<br><em>suppliers mapped</em>', ready: ready
						}
					:	{
						id: "Source SO#"+header.DocumentID.ID,
						desc: '<br>'+header.CustomerParty.Name+'<br><em>sourcing...</em>', ready: ready
						}
			}
		} else if (bod.name == 'ProcessQuote') {
			var ready = !WIP[bodid].WIP
			var bodHeader = bod.DataArea.Quote.QuoteHeader
			if (bod.ApplicationArea.Receiver == 'sales') { //quote from supplier
				var soid = bodHeader.DocumentReference.SalesOrderReference.DocumentID.ID
				var so = getSO(soid)
				var header = so.SalesOrderHeader
				card = ready
					? {
						id: "Quote SO#"+header.DocumentID.ID,
						desc: '<br>'+bodHeader.SupplierParty.Name+'<br><em>quote received</em>', ready: ready
						}
					:	null
			} else { //quote to customer
				var refBOD = getBOD(getRef(bod))

				// TODO this is not required for tests.js, but there are data in the "real" database which need this condition
				if (refBOD.name == 'ProcessRFQ') {
					var header = refBOD.DataArea.RFQ.RFQHeader
					card = ready
						? {
							id: "Quote SO#"+bodHeader.DocumentID.ID,
							desc: '<br>'+header.CustomerParty.Name+'<br><em>quote sent</em>', ready: ready
							}
						:	null
				// end of not required part

				} else if (refBOD.name == 'SyncSalesOrder') {
					var customerRFQ = getBOD(getRef(refBOD))
					var header = refBOD.DataArea.SalesOrder.SalesOrderHeader
					var rfqHeader = customerRFQ.DataArea.RFQ.RFQHeader
					card = ready
						? {
							id: "RFQ#"+rfqHeader.DocumentID.ID,
							desc: '<br>'+header.CustomerParty.Name+'<br><em>quote sent</em>', ready: ready
							}
						:	null
				}
			}
		} else card = {id: 'error', desc: 'Unknown BOD: '+bod.name}
		if (card) { var lane = cards[WIP[bodid].lane]
			lane.push(card); lane.splice(0, lane.length - 5)
		}
	}
	res.send(cards)
}
//exports.init_db(); // cannot call this in production mode...

exports.show_bod = function(req, res) {
	var bod = JSON.stringify(getBOD(req.params['bodid']), null,'  ')
	bod = bod.replace(
		/[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}/g,
		'<a href="/bods/$&">$&</a>')
	res.send('<pre>' + bod + '</pre>')
}

exports.ourselves = function(req, res) {
	res.send(ourselves)
}