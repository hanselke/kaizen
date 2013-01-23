10. Only show those actions that a user can create.
2. select the right roles for next action in sm and check.
2a ensure next action complete.
2b show current task name in header.
3. excel field mapping
4. Make it work with multiple process definitions.
5. store state machine in process definition
6. Show user in board and stuff
7. show time in board
8. clean user + stuff from bonita
9. Specify a running number for the task name (+ prefix from process definition)
12. clean out client from unnecessary code.
13. do nice error/status messages


http://ec2-54-251-77-171.ap-southeast-1.compute.amazonaws.com:8080/bonita
ssh -i ~/Documents/bitnami-hosting.pem ubuntu@ec2-54-251-65-125.ap-southeast-1.compute.amazonaws.com
http://www.bonitasoft.org/docs/javadoc/rest/5.5/API
How to install and start on the server:
Precon: mongodb installed locally

NODE_ENV=production npm install
NODE_ENV=production npm run-script assets
NODE_ENV=production node ./lib/index.js

You might want to run the last one inside forever

Docs:

The package.json file contains a couple of scripts that can and should be used as follows:

-> Starts in development mode. That means that the node process is restarted whenever a source fil e changes. See Tips section
* npm run-script dev-norestart
-> Starts in development mode but does not restart the process when the source changes.
* npm run-script dev-debug
-> Starts in development mode and activates debugging. You can launch a visual debugger (once you installed node-inspector) using the next command:
* npm run-script inspect
-> launches a chrome browser that allows you to debug your node.js app.
* npm run-script server-watch
-> This watches for changes in the coffeescript sourcecode and compiles it on the fly. It beeps on syntax errors.

## Typical Dev Environment

You launch 2 shells, one with

npm run-script dev

and one with

npm run-script server-watch

## Config

The /config/env folder contains 3 config json files, one for each environment. Take a look at the config settings for the mongodb database, that's the crucial one. It works for dev and test, but needs to be adjusted for production

## Tips
* You can use https://github.com/nodejitsu/forever to keep node processes running forever. It restarts them on crash.
* Install police (npm install -g police) to ensure that your node.js app uses the latest versions.
* Install nodemon to restart during development (npm install -g nodemon) - this is triggered in the script: npm run-script dev
* Install node-inspector (npm install -g node-inspector) for debugging.
* Install bower (npm install -g bower) for client side component management
* Install less (npm install -g less) to make bootstrap work
* use the script update-components to update the client side components (./bin/update-components)
* Use npm-install to update the node_modules. When doing that on the server, make sure your environment is set to production
* For keeping the process running as an alternative to forever: https://github.com/visionmedia/mon

## Admin Endpoints

* Sync users into bonita: curl -X POST -d '{}' -H 'Content-Type: application/json' -H 'Accept: application/json' http://127.0.0.1:8001/admin/users/sync-to-bonita
* Add a user to passport and bonita curl -X POST -d '{"username" : "mw9", "password": "testabc", "primaryEmail": "mw9@test.com","roles" : ["admin","sales","purchasing"]}' -H 'Content-Type: application/json' -H 'Accept: application/json' http://127.0.0.1:8001/admin/users/add-user-sync
* Adding roles to a user: curl -X POST -d '{"roles" :["admin","user","test"]}' -H 'Content-Type: application/json' -H 'Accept: application/json' http://127.0.0.1:8001/admin/users/mw1/roles

===


1, a createrfq page kuld a szervernek egy BOD-ot, jelenleg a POST /sales -re. a verb process
2, ezt a dokumentumot kene latnia a sales usernek a processrfq page-en
3, ezert az rfq-bol csinal a backend egy SalesObject-et, amit belerak a queue-ba
4, ebbol a queue-bol fogja a GET /next_task kivenni a bod-okat
(talan szerencsesebb lenne taskQueue-nak hivni BODQueue helyett)
5, a processrfq page-en, mikor kesz van az osszekapcsolas az inventory itemekkel, akkor meg kell adni a Quote-on szereplo arakat
6, ezutan visszakuldi a szervernek ezt a BOD-ot (ami egy masik bod kene h legyen talan, de nem tudom)
7, amit az eltarol, es kikuldi a quote-ot emailben a buyer-nek


Primitive RFQ-Quote workflow:

Feature: Customer sends RFQ to Sales
	As a Customer
	I want to send and RFQ to a supplier Sales department
	So I can get the prices for the parts I want to buy

Feature: Sales man picks an RFQ to turn it into a Quote
	As a Sales man
	I should get a new RFQ if there are any
	So I can create a Quote based on it

Feature: Sales sends Quote to Customer
	As a Sales man
	I should be able to send prices for requested parts to a Customer
	So I can get an actual Order for those parts later



RFQ-Inventory-Quote workflow assuming subsystems:

Feature: Customer sends RFQ to OrderMgt
	As a Customer
	I want to send and RFQ to a Supplier
	So I can get prices for the parts I want to buy

Feature: OrderMgt prepares SalesOrder from RFQ for inventory mapping by Sales
	As the OrderMgt subsystem
	I should send a SalesOrder to SalesMgt containing all the info from an RFQ
	And having place for mapping Inventory items to the line items
	So Sales man can map the actual items on stock to the requested items

Feature: Sales man sends SalesOrder to OrderMgt after mapping Inventory
	As a Sales man
	I want to send a SalesOrder to OrderMgt
	where each line item is mapped to 0 or more Inventory item
	So deciding about prices can take the following into account:
	  - part availability
	  - part source price
	  - sales history of a part

Feature: OrderMgt prepares SalesOrder for populating prices
	As the OrderMgt subsystem
	I should extend the SalesOrder with price fields for the line items
	So Sales man can decide about the price to Quote

Feature: Sales man send SalesOrder to OrderMgt after pricing
	As a Sales man
	I want to send a SalesOrder to OrderMgt
	So it can prepare and send a Quote for the Customer

Feature: OrderMgt sends priced SalesOrder as Quote to Customer
	As the OrderMgt subsystem
	I should send a Quote to a Customer based on prices in the SalesOrder
	So I can hope to get a PurchaseOrder from the Customer later

Feature: Sales man can see their past Quotes
	As a Sales man
	I should be able see all the Quotes any sales guy issued
	in case of dispute

Feature: Sales man can see sent Quotes to a specific Customer
	As a Sales man
	I should be able see all the Quotes issued for a specific customer
	So I can give quotes based on the prices I see there
	# Or verify incoming POs against it?... this should be automated


# ==================================

Def(OpenB): Open Business Online Procurement Platform

RFQ-Inventory-Quote workflow without implementation assumptions:

Feature: Customer sends RFQ to OpenB
	As a Customer
	I want to send and RFQ to a Supplier
	So I can get prices for the parts I want to buy

Feature: OpenB prepares SalesOrder from RFQ for Inventory mapping
	As OpenB
	I should file a SalesOrder
	  - containing all the info from an RFQ
	  - and having place in it for mapping Inventory items to the line items
	So Sales man can do the mapping

Feature: Sales man picks a SalesOrder for Inventory mapping
	As a Sales man
	I should be able to get an available initial SalesOrder which
	  - is missing Inventory references
	  - nobody started to work on yet
	  - amongst these it should be based on the oldest received RFQ
	So I can start connecting the line item descriptions to actual Inventory items

Feature: Sales man updates SalesOrder with Inventory item mappings
	As a Sales man
	I want to update the line items of an OpenB SalesOrder
	  with 0 or more Inventory item reference
	So later deciding about prices can take the following into account:
	  - part availability
	  - part source price
	  - sales history of a part

Feature: OpenB prepares SalesOrder for populating prices
	As the OpenB
	I should extend the SalesOrder with price fields for each line item
	So Sales man suggest prices for Quotation

Feature: Sales man picks a SalesOrder for pricing
	As a Sales man
	I should be able to get an available mapped SalesOrder, meaning it
	  - has Inventory references
	  - has no prices yet
	  - nobody started to work on yet
	  - amongst these it should be based on the oldest received RFQ
	So I can coming up with prices (discounts, etc)

Feature: Sales man updates SalesOrder with prices
	As a Sales man
	I want to send a SalesOrder to OpenB price suggestions
	So it can prepare sending a Quote for the Customer

Feature: OpenB sends Quote to Customer
	As OpenB
	I should send a Quote to a Customer based on
	- original line items descriptions from their RFQ
	- prices in the SalesOrder
	So I can hope to get a PurchaseOrder from the Customer later





{name: "", pwd: ""} -> /login ->
  {"company_name":"x","email":"andras@openbusiness.com.sg","id":"admin","roles":["sales","purchasing"]}
  {msg: 'No current user', status:'error'}
  session cookie

registration: POST /users
login: POST /login  -> "ok", "perm denied" session cookie
GET /current_user (session cookie) -> user object
GET /users/:id
POST /users/:id


customer -> fax / email / phone -> secretary
secretary -> ProcessRFQ -> sales mgt
sales mgt -> ProcessRFQ -> order mgt
order mgt -> ProcessSalesOrder -> task mgt
task mgt <- inventory
sales man <- SyncSalesOrder <- task mgt
sales man -> SyncSalesOrder (inventory items mapped) -> sales mgt
sales mgt -> SyncSalesOrder (place for price) -> order mgt
order mgt -> ProcessSalesOrder (place for price) -> task mgt
sales man <- SyncSalesOrder (place for price) <- task mgt
sales man -> SyncSalesOrder (priced) -> sales mgt


Example BOD:

ProcessRFQ
ApplicationArea
DataArea
Process
Sender: Customer
RFQ
customer party (id?)
line items (qty, unit, desc)

ProcessSalesOrder (w inventory)
Process
SalesOrder
rfq party info
rfq line items
place for inventory ids
PriceList (this is the "inventory")
id
desc
price

SyncSalesOrder (inventory items mapped)
Sync
SalesOrder
line items with inventory (catalog?) references & 

No PriceList

ProcessSalesOrder (place for price)

SyncSalesOrder (priced) 



session.js/server.js


sales.js
- #/createrfq -> POST /sales ProcessRFQ -> post() -> ProcessRFQ() -> order.ProcessRFQ() -> "accepted"
- #/sales/processrfq -> POST /sales SyncSalesOrder -> post() -> SyncSalesOrder() -> order.SyncSalesOrder() -> "ok"


order.js
- ProcessRFQ -> task.add_task() -> "accepted"
- SyncSalesOrder -> task.add_task() -> "ok"

task.js
- sales.post_ProcessRFQ() -> add_task()
- GET /next_task -> next_task() ->
ProcessSalesOrder (w inventory)
ProcessSalesOrder (inventory mapped)
line items extended w price (currency, etc...)
- handle task queue-ing for users

inventory.js
GET /inventory -> getInventory() -> {items: []}



==========================================

XML file (can only have 1 root tag):
<ProcessRFQ>
  <inner>
  </inner>
</ProcessRFQ>
<ProcessSalesOrder>
</ProcessSalesOrder>

{
    "ProcessRFQ": {
        "inner": {}
    }
    "ProcessSalesOrder": {}
}


Two possible formats for a BOD:

{
    "ProcessRFQ": {
        "ApplicationArea": {}
        "DataArea": {}
    }
}

{
    "BOD": "ProcessRFQ"
    "ApplicationArea": {}
    "DataArea": {}
}




========= discussion log from friday before i left singapore =======


1. Dropbox -> Backoffice Queue
2, show ready faxes in the customer lane
     date time
3, allow Backoffice to choose input type RFQ/PO/Quote/Forward fax to admin@guanhuathardware.com
     attach the image file
     move it into a "forwarded" dir
4, RFQ needs delivery time and payment term (cash on delivery / 50% TT (Telegraphic Transfer) 50% cash on delivery / 30day credit term) input field for the whole RFQ below the line item list
5, delivery time for each line item (free form for now)
6, auto refresh kanban board should be linked to actions
7, inventory mapping should not show inventory item prices.
    so only need to show the item's description?
    yes
    if all the stock levels of the mapped inventory items are less then the corresponding line item quantity, then add it to the sourcing list
8, multiple inventory item selection should be possible:
     - click map
     - allow selecting / deselecting items
     - starting another mapping finalizes the selection
     - the Done submission button should also finalize selections
9, show sign in form by default
10, the WIP kanban card should have dark green by
handle upside down faxes
handle multi-page faxes
supplier mapping screen
handle multiple supplier mapping for each line item
take out the address info (purchasing doesn't have to know who is the buyer)
show the RFQ #
submission confirmation should show the submitted info and offer the next task button
make it visually different from the editable form (disable controls)
kanban board would also reflect there is no active task
outRFQ screen
show phone numbers
missing supplier contact info (phone / fax / email) should be addable
after filling out the prices, we should send a confirmation fax of the Quote to the supplier
email is optional
fax is a must
we need an ID for such a "self-issued" quotation
it should be marked as a "phone quote", because it's not a legally binding document
payment and delivery terms should also appear on the quotes
and should be copied from the outRFQ
the outRFQ have the payment terms filled out with a default
purchasing doesnt have to see payment terms
in case of fax/email/print payment terms should be editable by the backoffice
left column should show a quotation for the 1st supplier
right column should act more like a progess indicator w the list of supplier names
confirmation screen should show the supplier names only, it's ok
Sourcing card should go into Customer lane as WIP with a counter for the incoming quotes. Customer lane??  Supplier lane actually...
inQuote FAX screen of the Backoffice
if no Sales Order ID, then we have to map it to an RFQ
show the non replied list of RFQs
right side is already taken by the fax image, so this should be a popup or other screen
we should list the outstanding (non-replied) rfqs only
after the SOID is determined, the Quote WIP card disappears and the Sourcing card's counter increments OR turns into ready if it reached the max counter value
since we know the cost, we should have a profit margin field which would calculate each selling price, but after changing this field, individual prices should be overwriteable
use cheapest quote for each line item
as individual selling prices are changed, the profit margin should be updated to reflect the average margin
Kanban board
cycle time = value added time + wasted (waiting) time
cycle cost (salries divided by )
value added time
calculate for each lane and total also
might be a good idea to exclude weekend from the cycle time averages
show monthly avgs




=========== kanban simulation with an extra order mgt column =======


1
S O P
W                   mapping inventory

2
S O P
R                       inventory mapped done. ready to pull by order mgt

3
S O P
   W                process inventory mapping WIP.

4
S O P
   R                process supplier mapping ready to pull by purchasing

5
S O P
      W     supplier mapping WIP

6
S O P
      R     supplier mapping done. ready to pull by order mgt

7
S O P O
        W   


Version 1

1
S  P
W

2 similar to 4
S  P
R                   process supplier mapping ready to pull by purchasing



Version 2

1
S  P
W

2 similar to original 2
S  P
R                   inventory mapped done. supplier mapping is ready to pull by purchasing


Version 3

1
S  P
W

2
S  P
D   R               inventory mapped done. supplier mapping is ready to pull by purchasing


Version 4

1
S  P
W

2
S  P
    R               inventory mapped done. supplier mapping is ready to pull by purchasing


