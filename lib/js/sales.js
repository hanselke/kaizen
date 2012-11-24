require('utils').init(Object)
var oagis = require('./oagis');
var email = require('mailer');
var BODs, RFQs, SOs, Quotes, BODQueue, userTask;

exports.init = function() {
	BODs = {}, currentBODID = 0;
	RFQs = {}, currentRFQID = 0;
	SOs = {}, currentSOID = 0;
	Quotes = {};
	BODQueue = [];
	userTask = {}; // the current tasks. key: user.id, value: task.id
}

function nextBODID() {return ++currentBODID}
function nextRFQID() {return ++currentRFQID}
function nextSOID() {return ++currentSOID}

exports.ProcessRFQ = function (req, res) {
	var bod = req.body;
	// check if buyer has email address
	if (!bod.DataArea.RFQ.RFQHeader.CustomerParty.Contact.Communication.UserArea.Email) {
		return res.send({msg: 'Please enter the valid email address of the customer. '+
				'The Quote will be sent to this email.', status: 'error'}, 400);
	}
	console.log('bod:', JSON.stringify(bod));
	var bodID = nextBODID();
	bod.ApplicationArea.BODID = bodID;	// the BOD should know about itself :)
	var docID = nextRFQID();
	// bod.DataArea.RFQ.RFQHeader.DocumentID = docID;
	rfq = bod.DataArea.RFQ;
	BODs[bodID] = bod; //the originally received document
	RFQs[docID] = rfq;
	rfq.bodIDs = [bodID];
	// create SalesOrder object from the RFQ and add it to the queue as a task
	var sales_order = RFQ_To_SalesOrder(rfq, Date.now());
	var sales_order_bod = {
		ApplicationArea: {
			Sender: 'Order Management',
			BODID: nextBODID()
		},
		DataArea: {
			Process: {},
			SalesOrder: sales_order
		}
	}
	BODs[sales_order_bod.ApplicationArea.BODID] = sales_order_bod;
	BODQueue.push(sales_order_bod); //add the SalesOrder BOD to the queue
	if (bod.DataArea.RFQ.RFQLine.length > 0)
		res.send( {msg: "Accepted", status: "ok"} )
	else
		res.send( {msg: "Not Found", status: "error"}, 404 );
}

exports.latestRFQasQuote = function (req, res) {
	var rfq = RFQs[currentRFQID];
	if (!rfq) return res.send({msg: "No RFQ", status: "error"}, 404);
		// This is the "null" Order Management for now
		var sales_order = RFQ_To_SalesOrder(rfq, Date.now());
		var quote = SalesOrder_To_Quote(sales_order, Date.now());
	res.send(
		{
			ApplicationArea: {
				Sender: "Order Management",
				BODID: null
			},
			DataArea: {
				Quote: quote
			}
		}
	);
}
exports.next_task = function(req, res) {
	if (!req.session.currentUser) return res.send({msg: 'No signed in', status: 'error'}, 403);
	if (userTask[req.session.currentUser.id]) {
		//todo check if the bod exists and the owner is this user
		//redirects to send the bod to the user
		res.redirect('/bod/'+userTask[req.session.currentUser.id]);
		return;
	}
	var bod = BODQueue.splice(0, 1); //removes the first element from the queue
	if (bod.length == 0) return res.send({msg: 'No unprocessed task', status: 'error'}, 404);
	bod = bod[0];
	//mark that the current user is working on this bod
	userTask[req.session.currentUser.id] = bod.ApplicationArea.BODID;
	res.send(bod);
}
exports.sync_sales_order = function(req, res) {
	if (!req.session.currentUser) return res.send({msg: 'No signed in', status: 'error'}, 403);
	var bod = req.body;
	// check if the user is the owner of this bod
	if (userTask[req.session.currentUser.id] != bod.ApplicationArea.BODID) {
		return res.send({msg: 'You have no permission to sync this document', status: 'error'}, 403);
	}
	// store the updated bod
	BODs[bod.ApplicationArea.BODID] = bod;
	// revoke this task from the user
	delete userTask[req.session.currentUser.id];
	// add the task to the end of the queue
	BODQueue.push(bod);
	return res.send({msg: 'Accepted', status: 'ok'});
}
exports.bod = function(req, res) {
	if (!req.session.currentUser) return res.send({msg: 'No signed in', status: 'error'}, 403);
	var bodid = req.params.bodid;
	var bod = BODs[bodid];
	if (!bod) return res.send({msg: 'No such bod', status: 'error'}, 404);
	res.send(bod);
}
exports.SendQuoteToBuyer = function(req, res) {
	if (!req.session.currentUser) return res.send({msg: 'No signed in', status: 'error'}, 403);
	var bod = req.body;
	// FIXME validate the structure here
	// todo check that this bod is a response for the document what the current user is working on
	var bodID = nextBODID();
	bod.ApplicationArea.BODID = bodID;	// the BOD should know about itself :)
	var quote = bod.DataArea.SalesOrder;
	quote.bodIDs = [bodID];
	BODs[bodID] = bod; //the originally received document
	//send the Quote to the buyer by email
	var email = bod.DataArea.SalesOrder.SalesOrderHeader.CustomerParty
		.Contact.Communication.UserArea.Email;
	sendEmail(email, 'Your Quote', 'This is the Quote: '+JSON.stringify(quote));
	res.send({msg: "Accepted", status: "ok"});
}
exports.ProcessQuote = function (req, res) {
	var bod = req.body;
	quote = bod.DataArea.Quote;
	docID = quote.QuoteHeader.DocumentID.ID;
	BODs[bodID] = bod;
	Quotes[docID] = quote;
	res.send({});
}

function sendEmail(to, subject, body) {
	email.send({
		host: "smtp.gmail.com",
		port : "465",
		domain: "smtp.gmail.com",
		authentication: "login",
		ssl: true,
		username: 'orders@openbusiness.com.sg',
		password: "ordersX%Y3y",
		to : to,
		from : "orders@openbusiness.com.sg",
		subject : subject,
		body : body},
		function(err, result){
			if (err) {
				//cannot really do anything, it was asynchron...
				console.log('Error while sending email:', err);
			}
		}
	);
}
/*
As the Sales Management subsystem,
I should be able to receive and store a ProcessRFQ message,
So Sales users can pick it and turn it into a Quote.
*/


var RFQ_To_SalesOrder = function (rfq, $ts) {
	sales_order = {
		SalesOrderHeader: {
			DocumentID: rfq.RFQHeader.DocumentID,
			LastModificationDateTime: $ts,
			DocumentDateTime: $ts,
			CustomerParty: rfq.RFQHeader.CustomerParty,
			SupplierParty: oagis.PartyType,	// FIXME should be the company itself
			// FIXME non OAGIS complaint :
			RFQReference: {DocumentID: rfq.RFQHeader.DocumentID}
		},
		SalesOrderLine: []
	}
	rfq.RFQLine.forEach( function(line,index,arr){
		sales_order.SalesOrderLine.push(line.extend({
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
		}));
	});
	return sales_order;
}

var SalesOrder_To_Quote = function (sales_order, $ts) {
	var quote = {
		QuoteHeader: sales_order.SalesOrderHeader,
		QuoteLine: []
	};
	quote.QuoteHeader.LastModificationDateTime = $ts;
	quote.QuoteHeader.DocumentDateTime = $ts;
	quote.QuoteLine = sales_order.SalesOrderLine;
	return quote;
}

exports.init();