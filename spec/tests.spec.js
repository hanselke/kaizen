var sales = require('../sales')

describe('sales modul', function(){

	describe('ProcessRFQ', function(){
		it('should be able to send an RFQ and get back the BOD id and RFQ id', function(){
			var req = {
				body: {
					ApplicationArea: {},
					DataArea: {
						RFQ: {
							RFQHeader: {
								DocumentID: null},
							RFQLine: []}}}
			}
			var res = {send: function(obj){
				expect(obj).not.toBeFalsy()
				expect(obj.bodID).not.toBeFalsy()
				expect(obj.docID).not.toBeFalsy()
			}}
			sales.ProcessRFQ(req, res)
		})
	})

	describe('latestRFQasQuote', function(){
		// it will be failed because the previous test has already added an RFQ...
		it('should throw an error when there are no RFQs', function(){
			var req = {}
			var res = {send: function(obj, code){
				expect(code).toBe(500)
			}}
			sales.latestRFQasQuote(req, res)
		})
		it('should return the RFQ what i send before converted to a Quote', function(){
			var rfq = {
				body: {
					ApplicationArea: {},
					DataArea: {
						RFQ: {
							RFQHeader: {
								DocumentID: null,
								CustomerParty: {
									Name: 'Who is it?'}},
							RFQLine: [{}, {}]}}}
			}
			var res = {send: function(obj){
				expect(obj).not.toBeFalsy()
				expect(obj.bodID).not.toBeFalsy()
				expect(obj.docID).not.toBeFalsy()
			}}
			sales.ProcessRFQ(rfq, res)
			var res = {send: function(bod){
				expect(bod).not.toBeFalsy()
				expect(bod.ApplicationArea.BODID).not.toBeFalsy()
				expect(bod.ApplicationArea.Sender).toBe('Sales Management')
				expect(bod.DataArea.Quote.QuoteHeader.CustomerParty.Name).toBe('Who is it?')
				//check if i get back a deep copy of my RFQ, or a reference to that object
				rfq.body.DataArea.RFQ.RFQHeader.CustomerParty.Name = 'asd'
				expect(bod.DataArea.Quote.QuoteHeader.CustomerParty.Name).toBe('Who is it?')
				expect(bod.DataArea.Quote.QuoteLine.length).toBe(2)
			}}
			sales.latestRFQasQuote(undefined, res)
		})
	})

	// it('shows asynchronous test', function(){
	// 	setTimeout(function(){
	// 		expect('second').toEqual('secondd');
	// 		asyncSpecDone();
	// 	}, 1);
	// 	expect('first').toEqual('first');
	// 	asyncSpecWait();
	// });
});
