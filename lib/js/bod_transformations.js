var utils = require('utils'); utils.init(Object)
var matcher = require('./matcher'); matcher.init(Object)
var oagis = require('./oagis')
var request = require('request')
var inventory = require('./inventory').inventory
var suppliers = require('./suppliers').list
var ourselves = require('./ourselves').party
var fs = require('fs')

var latest_SOID = 1245
var SOs = {}

function saveSO(so) {
	SOs[so.SalesOrderHeader.DocumentID.ID] = so
}
function getSO(soid) {
	return SOs[soid]
}

exports.ProcessFax = function(fax, demo) {
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


exports.ProcessRFQ = function(ProcessRFQ, $ts) {
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

exports.ProcessSalesOrder = function(ProcessSalesOrder, $ts) {
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

function validate_Sync_supplier_mapped_SalesOrder(SyncSalesOrder) {
	var newSO = SyncSalesOrder.DataArea.SalesOrder
	for (var i in newSO.SalesOrderLine) {
		if (!newSO.SalesOrderLine[i].UserArea.SupplierID)
			return {status: "error", msg: 'All items should be mapped to a supplier.'}
	}
}

exports.Sync_supplier_mapped_SalesOrder = function(SyncSalesOrder, supplierid) {
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
	// var ProcessRFQs = []
	// Object.keys(rfqs).forEach( function(supplierid){ ProcessRFQs.push(rfqs[supplierid]) } )
	// return ProcessRFQs
	return rfqs[supplierid]
}

exports.Sync_quoted_SalesOrder = function(SyncSalesOrder) {
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

exports.Process_supplier_Quote = function(ProcessQuote) {
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

exports.ProcessPurchaseOrder = function(ProcessPurchaseOrder, $ts) {
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
