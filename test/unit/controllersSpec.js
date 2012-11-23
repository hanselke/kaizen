/* jasmine specs for controllers go here */

describe('Ordering system controllers', function(){
	describe('AppController', function(){
		var scope, $browser, ctrl;

		beforeEach(function() {
			scope = angular.scope();
			$browser = scope.$service('$browser');

			$browser.xhr.expectGET('/registration').respond({});
			$browser.xhr.expectGET('/current_user').respond({});
			ctrl = scope.$new(AppController);
		});


		it('should send a registration thru xhr', function() {
		});
	});

	describe('CreateRFQController', function(){
		var scope, $browser, ctrl;

		beforeEach(function() {
			scope = angular.scope()
			$browser = scope.$service('$browser')

			$browser.xhr.expectGET('/current_user').respond({email: "a@b"});
			var expectedRFQ = {
				name: 'ProcessRFQ',
				ApplicationArea: {Sender: 'Customer'},
				DataArea: {
					Process: {},
					RFQ: {
						RFQHeader: {
							DocumentID: null,
							LastModificationDateTime: null,
							DocumentDateTime: null,
							CustomerParty: {
								PartyIDs: {ID: []},
								AccountID: null,
								Name: 'Test Company',
								Location: {
									ID: null,
									Address: {
										ID: [],
										AttentionOfName: null,
										AddressLine: ['Test Address'],
										CityName: null,
										CountryCode: 'IT'}},
								Contact: {},
								CustomerAccountID: null}},
						RFQLine: [
							{Quantity: 123, Description: 'Test Item', LineNumber: 1, Quantity_unitCode: null},
							{Quantity: 234, Description: 'Another Test Item', LineNumber: 2, Quantity_unitCode: null}]}}
			}
			$browser.xhr.expectPOST('/sales|'+angular.toJson(expectedRFQ)).respond({status: 'ok'});
			ctrl = scope.$new(AppController)
			ctrl = ctrl.$new(CreateRFQController)
		});


		it('should be able add and remove items', function() {
			expect(ctrl.rfq).not.toBe(undefined)
			expect(ctrl.rfq.RFQHeader).not.toBe(undefined)
			expect(ctrl.rfq.RFQLine[0]).toEqual({})

			ctrl.rfq.RFQLine[0].Quantity = 123
			ctrl.rfq.RFQLine[0].Description = 'Test Item'
			expect(ctrl.rfq.RFQLine.length).toBe(1)
			
			ctrl.addItem()
			expect(ctrl.rfq.RFQLine.length).toBe(2)
			ctrl.rfq.RFQLine[1].Quantity = 222
			ctrl.rfq.RFQLine[1].Description = 'New Item'
			
			ctrl.deleteItem(0)
			expect(ctrl.rfq.RFQLine[0]).toEqual({Quantity: 222, Description: 'New Item'})
		});

		it('should receive the next task as a BOD and take out the SalesOrder document', function() {
			expect(ctrl.rfq).not.toBe(undefined)
			expect(ctrl.rfq.RFQHeader).not.toBe(undefined)
			expect(ctrl.rfq.RFQLine[0]).toEqual({})
			// fill rfq with some data
			ctrl.rfq.RFQHeader.CustomerParty.Name = 'Test Company'
			ctrl.rfq.RFQHeader.CustomerParty.Location.Address.AddressLine[0] = 'Test Address'
			ctrl.rfq.RFQHeader.CustomerParty.Location.Address.CountryCode = 'IT'
			ctrl.rfq.RFQLine[0].Quantity = 123
			ctrl.rfq.RFQLine[0].Description = 'Test Item'
			expect(ctrl.rfq.RFQLine.length).toBe(1)
			ctrl.addItem()
			expect(ctrl.rfq.RFQLine.length).toBe(2)
			ctrl.rfq.RFQLine[1].Quantity = 234
			ctrl.rfq.RFQLine[1].Description = 'Another Test Item'
			// send rfq
			ctrl.send()
		});
	});

	describe('ProcessRFQController', function(){
		var scope, $browser, ctrl;

		beforeEach(function() {
			scope = angular.scope()
			$browser = scope.$service('$browser')

			$browser.xhr.expectGET('/current_user').respond({email: "andras@openbusiness.com.sg"});
			ctrl = scope.$new(AppController)
			ctrl.setPreloadedBOD({
				name: 'SyncSalesOrder',
				ApplicationArea: {},
				DataArea: {
					Process: {},
					SalesOrder: {
						SalesOrderHeader:{
							CustomerParty:{
								Name:'Test Company',
								Location: {Address: {
									AddressLine: ['Test Address'],
									CountryCode: 'IT'}}}},
						SalesOrderLine: [
							{Quantity: 123, Description: 'Test Item',
							CatalogReference: {ItemID: [{ID: undefined}]}}]},
					PriceList: [
						{description: 'item1', price: 123, id: 'aaa'},
						{description: 'item2', price: 234, id: 'bbb'},
						{description: 'item3', price: 456, id: 'ccc'}]}
			})
			ctrl = ctrl.$new(ProcessRFQController)
		});

		it('should receive the next task as a BOD and take out the SalesOrder document', function() {
			expect(ctrl.bod).not.toBe(undefined)
			expect(ctrl.bod.name).toBe('SyncSalesOrder')
			expect(ctrl.bod.DataArea).not.toBe(undefined)
			expect(ctrl.salesOrder).not.toBe(undefined)
			expect(ctrl.salesOrder.SalesOrderHeader.CustomerParty.Name).toBe('Test Company')
			expect(ctrl.salesOrder.SalesOrderHeader.CustomerParty.Location.Address.AddressLine[0]).toBe('Test Address')
			expect(ctrl.salesOrder.SalesOrderHeader.CustomerParty.Location.Address.CountryCode).toBe('IT')
			expect(ctrl.salesOrder.SalesOrderLine[0]).toEqual({
				Quantity: 123, Description: 'Test Item', CatalogReference: {ItemID: [{ID: undefined}]}})
			expect(ctrl.inventory).not.toBe(undefined)
			expect(ctrl.inventory.length).toBe(3)
		});
		it('should be able to map inventory items to rfq items', function() {
			ctrl.mapItem(ctrl.salesOrder.SalesOrderLine[0])
			ctrl.connectItem(ctrl.inventory[0])
			expect(ctrl.salesOrder.SalesOrderLine[0].CatalogReference.ItemID).toEqual([{ID: 'aaa'}])
		});
	});
});
