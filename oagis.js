require('utils').init(Object)
var BOD = exports.BOD = {
	ApplicationArea: {Sender: null, Receiver: null, CreationDateTime: null, BODID: null},
	DataArea: null
}
var AddressType = exports.AddressType = {
	ID: [],
	AttentionOfName: null,
	AddressLine: [],
	CityName: null,
	CountryCode: null
}
var LocationType = exports.LocationType = {
	ID: null,
	Address: {
		ID: [],
		AttentionOfName: null,
		AddressLine: [],
		CityName: null,
		CountryCode: null,
		PostalCode: null
	}
}
var ContactType = exports.ContactType = {
	Name: null,
	Communication: {
		UserArea: {
			Phone: "",
			Fax: "",
			Email: ""
		}
	}
}
var PartyType = exports.PartyType = {
	PartyIDs: {ID: []},
	AccountID: null,
	Name: null,
	Location: LocationType.deepCopy(),
	Contact: ContactType.deepCopy()
}
var CustomerPartyType = exports.CustomerPartyType = {
	PartyIDs: {ID: []},
	AccountID: null,
	Name: undefined,
	Location: LocationType.deepCopy(),
	Contact: ContactType.deepCopy(),
	CustomerAccountID: null
}
var SupplierPartyType = exports.SupplierPartyType = {
	PartyIDs: {ID: []},
	AccountID: null,
	Name: undefined,
	Location: LocationType.deepCopy(),
	Contact: ContactType.deepCopy(),
}
var HeaderType = exports.HeaderType = {
	DocumentID: {ID: null},
	DocumentReference: {DocumentID: {ID: null}},
	LastModificationDateTime: null,
	DocumentDateTime: null
}
var RequestHeaderType = exports.RequestHeaderType = HeaderType.deepCopy().extend({
	CustomerParty: CustomerPartyType.deepCopy(),
	SupplierParty: SupplierPartyType.deepCopy(),
	Description: [],
	Note: [],
	DocumentDateTime: null,
})
var RFQLineType = exports.RFQLineType = {
	LineNumber: null,
	DocumentReference: {
		SalesOrderReference: {LineNumber: null}
	},
	Description: null,
	Quantity: null,
	Quantity_unitCode: null
}
var RFQ = exports.RFQ = {
	RFQHeader: RequestHeaderType.deepCopy(),
	RFQLine: []
}
var SalesOrder = exports.SalesOrder = {
	SalesOrderHeader: RequestHeaderType.deepCopy(),
	SalesOrderLine: []
}
var QuoteLineType = exports.QuoteLineType = {
	LineNumber: null,
	DocumentReference: {
		SalesOrderReference: {LineNumber: null}
	},
	Description: null,
	Quantity: null,
	Quantity_unitCode: null,
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
}
var Quote = exports.Quote = {
	QuoteHeader: RequestHeaderType.deepCopy().extend({
		DocumentReference: {
			SalesOrderReference: {DocumentID: {ID: null}}
		},
		RFQReference: {DocumentID: {ID: null}}
	}),
	QuoteLine: []
}
var PurchaseOrder = exports.PurchaseOrder = {
	PurchaseOrderHeader: RequestHeaderType.deepCopy(),
	PurchaseOrderLine: []
}

exports.ProcessRFQ = {
	name: "ProcessRFQ",
	ApplicationArea: {Sender: null, Receiver: null},
	DataArea: {
		RFQ: RFQ.deepCopy(),
		Process: null
	}
}
exports.ProcessQuote = {
	name: "ProcessQuote",
	ApplicationArea: {Sender: null, Receiver: null},
	DataArea: {
		Quote: Quote.deepCopy(),
		Process: null
	}
}
exports.ProcessSalesOrder = BOD.deepCopy().extend({
	name: "ProcessSalesOrder",
	DataArea: {
		Process: null,
		SalesOrder: SalesOrder.deepCopy()
	}
})
exports.SyncSalesOrder = BOD.deepCopy().extend({
	name: "SyncSalesOrder",
	DataArea: {
		Sync: null,
		SalesOrder: SalesOrder.deepCopy()
	}
})
exports.ProcessPurchaseOrder = BOD.deepCopy().extend({
	name: "ProcessPurchaseOrder",
	DataArea: {
		Process: null,
		PurchaseOrder: PurchaseOrder.deepCopy()
	}
})
