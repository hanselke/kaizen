describe('Ordering system', function() {

	beforeEach(function() {
		$.ajax({url: '/init_db', type: 'POST', async: false});
		browser().navigateTo('../../app/index.html');
	});

	it('should automatically redirect to /main when location hash/fragment is empty', function() {
	  expect(browser().location().hash()).toBe("/main");
	});

	describe('as a buyer, i should be able to register to be able to use the system', function() {

		it('i should see a "Sign in" link', function() {
			expect(element('#signin').text()).toBe('Sign in');
		});

		it('i should see a "Register" link', function() {
			expect(element('#register').text()).toBe('Register');
		});

	});


	describe('Registration view', function() {

		beforeEach(function() {
			element('#register').click();
		});

		it('should see the registration page after click on the registration link', function() {
			expect(element('ng\\:view h2').text()).toMatch(/Registration/);
		});

		it('i should see a Register button', function() {
			expect(element('ng\\:view #register').count()).toBe(1);
		});

		it('i should see a cancel button', function() {
			expect(element('ng\\:view #cancel').count()).toBe(1);
		});

		it('i should see the registration form with all the necessary details', function() {
			expect(element('ng\\:view input[name="email"]').count()).toBe(1);
			expect(element('ng\\:view input[name="password"]').count()).toBe(1);
			expect(element('ng\\:view input[name="company_name"]').count()).toBe(1);
		});

		it('[MANUAL TEST] i should be able to fill in the details and register', function() {
		});
		it('[MANUAL TEST] i should be automatically signed in after registration', function() {
		});
		it('[MANUAL TEST] i should be redirected to the main page after registration', function() {
		});
		it('[MANUAL TEST] after registration, i should receive a confirmation email to the entered email address', function() {
		});
		it('[MANUAL TEST] the confirmation email should contain a complete registration link', function() {
		});
	});

	describe('Sign in view', function() {

		beforeEach(function() {
			element('#signin').click();
		});

		it('should see the login page after click on the sign in link', function() {
			expect(element('ng\\:view h2').text()).toMatch(/Signin/);
		});
		it('i should be able to sign in with a proper email and password', function() {
			input('email').enter('sales@openbusiness.com.sg');
			input('password').enter('sales');
			element('input#signin').click();
			expect(element('#signedin_text').text()).toBe('You signed in as sales@openbusiness.com.sg.');
			element('a#signout').click();
		});
		it('i should see the main page after successfully signed in', function() {
			input('email').enter('sales@openbusiness.com.sg');
			input('password').enter('sales');
			element('input#signin').click();
			expect(element('#signedin_text').text()).toBe('You signed in as sales@openbusiness.com.sg.');
			expect(browser().location().hash()).toBe("/main");
			element('a#signout').click();
		});
		it('i should not be able to sign in with a wrong email or password', function() {
			input('email').enter('sales@openbusiness.com.sg');
			input('password').enter('wrong password');
			element('input#signin').click();
			expect(element('#signedin_text').count()).toBe(0);
		});
		it('i should stay on the sign in page after an unsuccessful sign in', function() {
			input('email').enter('sales@openbusiness.com.sg');
			input('password').enter('wrong password');
			element('input#signin').click();
			expect(browser().location().hash()).toBe("/signin");
		});
	});

	describe('85712 - Sales Management: Process RFQ Screen', function() {

		beforeEach(function() {
			element('a#signin').click();
			input('email').enter('andras@openbusiness.com.sg');
			input('password').enter('a');
			element('input#signin').click();
			//create an rfq for the test case
			$.ajax({url: '/faxes', type: 'POST', data: {image: 'RFQ'}, async: false});
			element('.role-selector :contains(backoffice)').click();
			element('#next_task').click();
			input('rfq.RFQHeader.CustomerParty.Name').enter('Test Company Name');
			input('rfq.RFQHeader.CustomerParty.Location.Address.AddressLine[0]').enter('Address line 1');
			input('rfq.RFQHeader.CustomerParty.Location.Address.AddressLine[1]').enter('Address line 2');
			input('rfq.RFQHeader.CustomerParty.Contact.Communication.UserArea.Email').enter('a@ob.com.sg');
			element('div.content tr[ng\\:repeat-index="0"] a').click()
			element('div.content tr[ng\\:repeat-index="0"] a').click()
			element('div.content tr[ng\\:repeat-index="0"] a').click()
			element('div.content tr[ng\\:repeat-index="0"] a').click()
			element('div.content tr[ng\\:repeat-index="0"] a').click()
			input('item.Quantity').enter('22');
			input('item.Description').enter('Item description');
			element('div.createrfq button').click();
			//go to the Process RFQ page
			element('.role-selector :contains(sales)').click();
			element('#next_task').click();
		});
		afterEach(function() {
			//sign out
			element('a#signout').click();
		});

		describe("As a Sales User, I should be able to see the RFQ side by side with an inventory window "+
				"which allows me to map my company's own inventory with each RFQ line item.", function() {
			it('I should be able to see the RFQ side by side with an inventory window', function(){
				expect(element('#rfq').count()).toMatch(1);
				expect(element('#inventory').count()).toMatch(1);
			});
			it('I should see the sender name and address of the RFQ', function(){
				expect(element('#sender_name').text()).toBe('Test Company Name')
				expect(element('#sender_address').text()).toMatch('Address line 1')
				expect(element('#sender_address').text()).toMatch('Address line 2')
			})
			it('I should see the the requested amount and the description of every items in the RFQ', function(){
				expect(repeater('.rfqitems tr', 'RFQ items list').column('item.Quantity'))
					.toEqual(['22'])
				expect(repeater('.rfqitems tr', 'RFQ items list').column('Description'))
					.toEqual(['Item description'])
			})
			it('I should see at least 1 item in the RFQ', function(){
				expect(repeater('.rfqitems tr.rfqitem', 'RFQ items list').count()).toBe(1)
			})
			it('I should see the description, amount and price of every inventory item', function(){
				var row = repeater('.inventoryitems tr', 'Inventory list')
				expect(row.column('description')).not().toEqual([])
				// expect(row.column('quantity')).not().toEqual([])
				expect(row.column('price')).not().toEqual([])
			})
			it('I should be able to filter the inventory items with an input field', function(){
				// it is not testable, since the inventory can contain any items, i cannot
				// create a new inventory with custom items
			})
			it('I should see a Done button', function(){
				expect(element('#done').count()).toBeGreaterThan(0)
			})
			it('I should be able to map an RFQ item with an inventory item', function(){
				element('table.rfqitems tr[ng\\:repeat-index="0"] input').click();
				element('table.inventoryitems tr[ng\\:repeat-index="0"]').click();
			});
			it('I should be able to remap a mapped RFQ item to an other inventory item', function(){
				element('table.rfqitems tr[ng\\:repeat-index="0"] input').click();
				element('table.inventoryitems tr[ng\\:repeat-index="0"]').click();
				element('table.rfqitems tr[ng\\:repeat-index="0"] input').click();
				element('table.inventoryitems tr[ng\\:repeat-index="2"]').click();
			});
		});

		describe("Once everything is mapped (or i click on done), the unstructured RFQ window will be "+
				"replaced with a quote window and the inventory window will be replaced by a customer "+
				"history window in order to send the quote back to the customer", function() {
			it("after all items in the RFQ has been mapped, i should see a quote window side by side with the "+
					"customer's previous RFQs and orders", function(){
			});
			it("should display the Profit Margin for the Quote", function(){
				//we didn't see the Profit Margin for the RFQ
				expect(element('#profitmargin').count()).toMatch(0);
				//map an RFQ item to an inventory item
				element('table.rfqitems tr[ng\\:repeat-index="0"] input').click();
				element('table.inventoryitems tr[ng\\:repeat-index="0"]').click();
				//click on Done button to change to Quote view
				element('#done').click();
				//now we should see the Profit Margin
				expect(element('#profitmargin').count()).toMatch(1);
			});
			it("if i click the done button, and there are unmapped items, the RFQ should send to purchasing "+
					"in order to map the missing items", function(){
			});
		});
	});

	describe('85717 - Purchasing: AddRFQ Screen', function() {

		beforeEach(function() {
			element('a#signin').click();
			input('email').enter('andras@openbusiness.com.sg');
			input('password').enter('a');
			element('input#signin').click();
			//go to the Process RFQ page
			element('#sendrfq').click();
		});
		afterEach(function() {
			//sign out
			element('a#signout').click();
		});

		describe("As a Purchasing user, I should see an RFQ and the suppliers "+
				"to be able to send out RFQs to the suppliers", function() {
			it('I should see an RFQ in one window, side by side with another '+
					'window in which i should see a list of suppliers (from yp) that '+
					'allow me to map the RFQ items to suppliers.', function(){
				expect(element('#rfq').count()).toMatch(1);
				expect(element('#suppliers').count()).toMatch(1);
			});
			it('I should be able to map an RFQ item with a supplier', function(){
				element('table.rfqitems tr[ng\\:repeat-index="0"] input').click();
				element('table.suppliers tr[ng\\:repeat-index="0"] input').click();
			});
			it('I should be able to remap a mapped RFQ item to an other supplier', function(){
				element('table.rfqitems tr[ng\\:repeat-index="0"] input').click();
				element('table.suppliers tr[ng\\:repeat-index="0"] input').click();
				element('table.rfqitems tr[ng\\:repeat-index="0"] input').click();
				element('table.suppliers tr[ng\\:repeat-index="2"] input').click();
			});
			it('When all items are mapped, I should be able to send out the RFQs '+
					'to the selected suppliers with the mapped RFQ items', function(){
				expect(element('#send').count()).toMatch(1);
			});
			it('I should see an Add supplier button and after I click on '+
					'it I should see a new window with a supplier form', function(){
				element('#addsupplier').click();
				expect(element('input[name="supplier.Name"]').count()).toBe(1);
				expect(element('input[name="supplier.Name"]').val()).toBe('');
			});
			it('I should see an Edit supplier button near every supplier and after I click on '+
					'it I should see a new window with a supplier form filled with the '+
					'supplier\'s details', function(){
				element('#editsupplier').click();
				expect(element('input[name="supplier.Name"]').count()).toBe(1);
				expect(element('input[name="supplier.Name"]').val()).not().toBe('');
			});
		});
	});

	describe('Session management', function(){
		beforeEach(function(){
		})
		it('As a user, i should be able to authenticate my identity (email and '+
				'password) and maintain it throughout my session', function(){
		})
		it("login with correct userid & password, should see page which confirms "+
				"my userid & i'm logged in", function(){
			element('a#signin').click()
			input('email').enter('andras@openbusiness.com.sg')
			input('password').enter('a')
			element('input#signin').click()
			expect(element('#signedin_text').text()).toBe('You signed in as andras@openbusiness.com.sg.')
		})
		it("load the page again and see that it remembers my userid & i'm logged in", function(){
			//this test loaded ad a separate page, so i should still be signed in
			expect(element('#signedin_text').text()).toBe('You signed in as andras@openbusiness.com.sg.')
		})
		it("when i click on sign out, i should be confirmed that i'm not logged in", function(){
			element('a#signout').click()
			expect(element('#signedin_text').count()).toBe(0)
		})
		it("load the page again and see that i'm still not logged in", function(){
			//this test loaded ad a separate page, so i still not be signed in
			expect(element('#signedin_text').count()).toBe(0)
		})
		it('[MANUAL TEST] if i am disconnected for 20 minutes, i should be automatically signed out', function(){
		})
	})

	describe('Role management', function(){
		beforeEach(function(){
			element('a#signin').click()
		})
		afterEach(function(){
			element('a#signout').click()
		})
		//with role
		it('if i sign in with a user who has Sales role, i should be able to access '+
				'the "Sales - ProcessRFQ" and "Sales - ProcessPO" pages', function(){
			input('email').enter('andras@openbusiness.com.sg')
			input('password').enter('a')
			element('input#signin').click()
			browser().navigateTo('#/processrfq');
			expect(element('.page').text()).toMatch('Process RFQ')
			browser().navigateTo('#/processpo');
			expect(element('.page').text()).toMatch('Process PurchaseOrder')
		})
		it('if i sign in with a user who has Purchasing role, i should be able to '+
				'access the "Purchasing - ProcessRFQ" and "Purchasing - ProcessPO" pages', function(){
			input('email').enter('andras@openbusiness.com.sg')
			input('password').enter('a')
			element('input#signin').click()
			browser().navigateTo('#/purchasing-processrfq');
			expect(element('.page').text()).toMatch('Process RFQ')
			browser().navigateTo('#/purchasing-processpo');
			expect(element('.page').text()).toMatch('Process PurchaseOrder')
		})

		//without role
		it('if i sign in with a user who doesn\'t have Sales role, i should not be able to access '+
				'the "Sales - ProcessRFQ" and "Sales - ProcessPO" pages', function(){
			input('email').enter('noroles@openbusiness.com.sg')
			input('password').enter('x')
			element('input#signin').click()
			browser().navigateTo('#/processrfq');
			expect(element('.page').text()).toMatch("You don't have permission to view this page.")
			browser().navigateTo('#/processpo');
			expect(element('.page').text()).toMatch("You don't have permission to view this page.")
		})
		it('if i sign in with a user who doesn\'t have Purchasing role, i should not be able to access '+
				'access the "Purchasing - ProcessRFQ" and "Purchasing - ProcessPO" pages', function(){
			input('email').enter('noroles@openbusiness.com.sg')
			input('password').enter('x')
			element('input#signin').click()
			browser().navigateTo('#/purchasing-processrfq');
			expect(element('.page').text()).toMatch("You don't have permission to view this page.")
			browser().navigateTo('#/purchasing-processpo');
			expect(element('.page').text()).toMatch("You don't have permission to view this page.")
		})
	})

	describe('Task management', function(){
		beforeEach(function(){
			element('a#signin').click()
			input('email').enter('sales@openbusiness.com.sg')
			input('password').enter('sales')
			element('input#signin').click()
		})
		afterEach(function(){
			element('a#signout').click()
		})
		it('as a user, i should see a "Next task" button after i signed in to the system', function(){
			expect(element('#next_task').count()).toBe(1)
		})
		function createRFQAndTestNextTask() {
			//create an rfq for the test case
			element('#createrfq').click()
			input('rfq.RFQHeader.CustomerParty.Name').enter('Apple')
			input('rfq.RFQHeader.CustomerParty.Location.Address.AddressLine[0]')
				.enter('Paris, near eiffel tower')
			input('rfq.RFQHeader.CustomerParty.Contact.Communication.UserArea.Email')
				.enter('andras@openbusiness.com.sg');
			input('item.Quantity').enter('100')
			input('item.Description').enter('Pear')
			element('div.createrfq button').click()
			//click on next task
			browser().navigateTo('#/main')
			element('#next_task').click()
			//now i should see this RFQ on the "Sales - ProcessRFQ" page
			expect(browser().location().hash()).toBe('/processrfq')
			//check the data on the screen
			expect(element('#sender_name').text()).toBe('Apple')
			expect(element('#sender_address').text()).toBe('Paris, near eiffel tower')
			expect(repeater('.rfqitems tr', 'RFQ items list').column('item.Quantity'))
				.toEqual(['100'])
			expect(repeater('.rfqitems tr', 'RFQ items list').column('Description'))
				.toEqual(['Pear'])
		}
		it('as a user, i should be assigned the next available task and i should see '+
				'this task when i click on the next task button', function(){
					createRFQAndTestNextTask()
		})
		it('as a user, i should be assigned to at most one task in any given time. if i click on the '+
				'Next task button again, i should see my already assigned task', function(){
			//click on next task
			element('#next_task').click()
			//now i should see this RFQ on the "Sales - ProcessRFQ" page
			expect(browser().location().hash()).toBe('/processrfq')
			//check the data on the screen
			expect(element('#sender_name').text()).toBe('Apple')
			expect(element('#sender_address').text()).toBe('Paris, near eiffel tower')
			expect(repeater('.rfqitems tr', 'RFQ items list').column('item.Quantity'))
				.toEqual(['100'])
			expect(repeater('.rfqitems tr', 'RFQ items list').column('Description'))
				.toEqual(['Pear'])
		})
		it('if i sign out for more than 1 hour, my currently assigned task will be '+
				'revoked from me and be assigned to someone else', function(){
			expect(0).toBe(1)
		})
		it('as a user, on the current task page, i should see a Skip task button', function(){
			createRFQAndTestNextTask()
			//i should see the skip button
			expect(element('#skip').count()).toBe(1)
			expect(element('#skip').text()).toBe('Skip task')
		})
		it('as a user, when i click on Skip task button, i need to enter a reason why '+
				'i want to skip my current task, and when i am finished, my current task '+
				'will be revoked from me and moved to the end of the processing queue. '+
				'when this task will be assigned to somebody, he should see the reason '+
				'why was it skipped', function(){
			createRFQAndTestNextTask()
			// click on the skip button
			element('#skip').click()
			// i have to see an input field where i can enter the reason
			expect(element('#reason').count()).toBe(1)
			// and ok and cancel buttons
			expect(element('button#ok').count()).toBe(1)
			expect(element('button#cancel').count()).toBe(1)
			// i should see the current task after click cancel
			element('button#cancel').click()
			expect(element('#reason').count()).toBe(0)
			// click on the skip button again
			element('#skip').click()
			// enter some reason and click ok
			input('reason').enter('Skip reason')
			element('button#ok').click()
			// i should see the main page
			expect(browser().location().hash()).toBe('/main')
		})
		it('As a multi role user, I should be assigned the same SalesOrder as my next '+
				'task if i have role permissions for the next step', function(){
			// finish sales user's ProcessRFQ 1st page (map inventory)
			// click next task, should be assigned Purchasing user's ProcessRFQ (map supplier)
			// click next task, should be assigned Sale user's ProcessRFQ 2nd page (quote)
			expect(0).toBe(1)
		})
		// it('as a user, i should see the id for my assigned task in the url', function(){})
		it('as a user, i should not be able to see any other task which is not assigned '+
				'to me, even if i know the url for that task', function(){
			expect(0).toBe(1)
		})
	})
});

describe('Receive Purchase Order', function() {

	beforeEach(function() {
		$.ajax({url: '/init_db', type: 'POST', async: false})
		browser().navigateTo('../../app/index.html')
	})

	function iCanGetAnEmptyPoForm() {
		element('button:contains("New PO")').click()
		expect(element('ng\\:view').text()).toMatch(/New Purchase Order/)
		expect(element('*[name*="DocumentID.ID"]').count()).toBe(1)
		expect(element('*[name*="Name"]').count()).toBe(1)
		expect(element('*[name*="AddressLine\\[0\\]"]').count()).toBe(1)
		expect(element('*[name*="AddressLine\\[1\\]"]').count()).toBe(1)
		expect(element('*[name*="Country"]').count()).toBe(1)
		expect(element('*[name*="PostalCode"]').count()).toBe(1)
		expect(element('*[name*="Phone"]').count()).toBe(1)
		expect(element('*[name*="Fax"]').count()).toBe(1)
		expect(element('*[name*="Email"]').count()).toBe(1)
		expect(element('*[name*="PaymentTerms"]').count()).toBe(1)
		expect(element('*[name*="DeliveryTime"]').count()).toBe(1)
		expect(element('*[name*="Quantity"]').count()).toBe(1)
		expect(element('*[name*="Description"]').count()).toBe(1)
	}
	function iCanTypeThePoDetails(){
		input('DocumentID.ID').enter("aaa")
		input('Name').enter("bbb")
		input('AddressLine\\[0\\]').enter("ccc")
		input('AddressLine\\[1\\]').enter("ddd")
		input('Country').enter("it")
		input('PostalCode').enter("eee")
		input('Phone').enter("111")
		input('Fax').enter("222")
		input('Email').enter("f@f.f")
		select('PaymentTerms').option("COD")
		input('DeliveryTime').enter("333")
		input('Quantity').enter("444")
		input('Description').enter("ggg")
	}
	it('I should be able to get an empty PO form', 	iCanGetAnEmptyPoForm)

	it('so I can type the PO details', function(){
		iCanGetAnEmptyPoForm()
		iCanTypeThePoDetails()
	})

	it('and I can submit the form', function(){
		iCanGetAnEmptyPoForm()
		iCanTypeThePoDetails()
		element('button:contains("Done")').click()
		expect(browser().location().hash()).toBe("/");
	})

})
