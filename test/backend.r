#!/usr/local/bin/rebol -qws
REBOL [
	Title: "Open Business backend test suite"
	Author: onetom@openbusiness.com.sg
	Date: 2011-11-28
]

do %env.r
steps: []
append steps load %backend.steps
append steps load %po.steps

Suite "Order Management"
	before-each: does [ reset_http_client   send init_db   send restart
		task: rfq: po: header: original_items: new_items: items: item: lines: sales_order: i: quote: none]
	before-each-step: does [ within none ]

do load %backend.features
do load %po.features

print summary




comment {
the cycle can start with either of the following:
- Fax
- Email
- Phone call
- ProcessRFQ  BOD
- ProcessPurchaseOrder  BOD

ProcessRFQ
	ApplicationArea/CreationDateTime  http://www.schemacentral.com/sc/oagis941/e-ns1_CreationDateTime.html
	DataArea/[Noun]/[HeaderType]
		LastModificationDateTime
		DocumentDateTime

ProcessSalesOrder
SyncSalesOrder
ProcessQuote

user:	u0	u1	u2	u3
step:	a	b	c	d
t0	d0			
t1		b(d0)		
t2				
t3				
t4				
t5				
}






