var utils = require('utils'); utils.init(Object)
var matcher = require('./matcher'); matcher.init(Object)
var oagis = require('./oagis')
var request = require('request')
var inventory = require('./inventory').inventory
var suppliers = require('./suppliers').list
var ourselves = require('./ourselves').party
var bod_transformations = require('./bod_transformations')
var fs = require('fs')

var repl = require('repl')
repl = repl.start('node in backend> ')
init_repl()

var users, Q, allTasks, uuid, WIP

function init_repl() {
	repl.context.users = users
	repl.context.Q = Q
	repl.context.allTasks = allTasks
	repl.context.uuid = uuid
	repl.context.WIP = WIP
}

exports.set_db_dir = function(){}
exports.init_db = function(){
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
  "hanselke@gmail.com": {
    "company_name": "openbiz",
    "id": 3,
    "password": "hansell1",
    "roles": [
    	"backoffice",
      "sales",
      "purchasing"
    ],
    name: 'Hansel Ke',
    avatar: 'hansel',
    "email": "hanselke@gmail.com"
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
	exports.Q = Q = []
	exports.allTasks = allTasks = {}
	exports.uuid = uuid = 1000
	exports.WIP = WIP = new WIPClass()

	init_repl()
}
function WIPClass(){
	var that = this
	this.tasks = []
	this.addTask = function(task_id){
		if (that.tasks.indexOf(task_id) < 0) {
			that.tasks.push(task_id)
		}
	}
	this.removeTask = function(task_id){
		if (that.tasks.indexOf(task_id) >= 0) {
			that.tasks.splice(that.tasks.indexOf(task_id), 1)
		}
	}
	this.forEach = function(callback){
		that.tasks.forEach(callback)
	}
}
exports.current_user = function(req, res){
  req.current_user ? res.send(req.current_user) : res.send({}, 404)
}
//app.post('/users', backend.create_user);
exports.create_user = function(req, res){
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

exports.logout = function(req, res) {
	req.session.destroy()
	res.send({})
}
function Task(for_who, type, data, prev_task_id){
	this.id = uuid++ // the task's unique id
	this.for_who = for_who // this task is for users with this role
	this.type = type // the task type, or status
	this.data = data // the data which will be used to generate the next task
	this.prev_task_id = prev_task_id // the previous task id which this task was generated from
	this.events = [] // log records for this task
	var that = this
	this.add_event = function(who, what, when){
		that.events.push({when: when || new Date(), who: who, what: what})
		console.log('['+that.id+', '+that.type+'] '+who+' '+what)
	}
	this.add_event('system', 'create task')
	allTasks[this.id] = this
}
function addTask(task){
	Q.push(task.id)
}
exports.create_fax = function(req, res) {
// curl -D- -H 'Content-Type: application/json' http://localhost:8001/faxes -d '{"image": "RFQ"}'
	var fax = req.body
	addTask( new Task('backoffice', 'incoming fax', fax) )
	res.send({})
}

//app.post('/sales', andLoggedIn, backend.create_task);
exports.create_task = function(req, res){
	var task_id = req.current_user.latest_task || (req.body && req.body.UserArea && req.body.UserArea.task_id)
	if (!task_id) {
		throw new Error("You don't have a current task!")
	}
	var task = allTasks[task_id]
	if (!task) throw new Error('Unknown task: '+task_id)
	task.add_event(req.current_user.email, 'complete task')
	if (task.type == 'incoming fax') {
		var header = req.body.DataArea.RFQ.RFQHeader
		task.board_data = {id: 'RFQ#'+header.DocumentID.ID,
			desc: '<br>'+header.CustomerParty.Name, ready: true}
		addTask(new Task('sales', 'inventory mapping customer RFQ', req.body, task.id))
	} else if (task.type == 'inventory mapping customer RFQ') {
		var o = task.data
		task.board_data = {id: 'RFQ#'+o.matcher("Header/'DocumentID/'ID"),
			desc: '<br>'+o.matcher("Header/'CustomerParty/'Name")+
				'<br><em>inventory mapped</em>', ready: true}
		var n = 0
		var SO = req.body.DataArea.SalesOrder
		SO.SalesOrderLine.forEach(function(item){
			if (item.CatalogReference.ItemID[0].ID) n++
		})
		if (n == SO.SalesOrderLine.length) { //full inventory mapping
			addTask(new Task('sales', 'pricing full inventory mapped customer Quote', req.body, task.id))
		} else {
			addTask(new Task('purchasing', 'supplier mapping customer RFQ', req.body, task.id))
		}
	} else if (task.type == 'supplier mapping customer RFQ') {
		var data = req.body
		//count the number of mapped suppliers
		var supplier_ids = []
		var newSO = data.DataArea.SalesOrder
		console.log('newSO:', newSO)
		for (var i in newSO.SalesOrderLine) {
			var id = newSO.SalesOrderLine[i].UserArea.SupplierID
			console.log('mapped supplier id:', id)
			if (!id) return res.send({status: "error", msg: 'All items should be mapped to a supplier.'}, 400)
			if (supplier_ids.indexOf(id) < 0) supplier_ids.push(id)
		}
		var o = task.data
		task.board_data = {id: 'Source SO#'+o.matcher("Header/'DocumentID/'ID"),
			desc: '<br>'+o.matcher("Header/'CustomerParty/'Name")+
				'<br><em>suppliers mapped</em>', ready: true}
		addTask(new Task('backoffice', 'sending out supplier RFQ',
			{data: data, supplier_index: 0, supplier_ids: supplier_ids}, task.id))
	} else if (task.type == 'sending out supplier RFQ') {
		if (req.body.name == 'ProcessQuote') {
			task.board_data = {id: 'Quote SO#'+task.data.matcher("Header/'DocumentID/'ID"),
				desc: '<br>'+req.body.matcher("Header/'SupplierParty/'Name")+
					'<br><em>quote received</em>', ready: true}
			addTask(new Task('sales', 'check if all supplier Quote arrived', req.body, task.id))
		} else {
			throw new Error('Unhandled submitted document for "sending out supplier RFQ"! doc.name: '+req.body.name)
		}
	} else if (task.type == 'pricing customer Quote') {
		task.board_data = {id: 'RFQ#'+task.data.matcher("Header/'DocumentID/'ID"),
			desc: '<br>'+req.body.matcher("Header/'CustomerParty/'Name")+
				'<br><em>quoted</em>', ready: true}
		addTask(new Task('backoffice', 'sending out customer Quote', req.body, task.id))
	} else if (task.type == 'sending out customer Quote') {
		task.board_data = {id: 'RFQ#'+task.data.matcher("Header/'DocumentID/'ID"),
			desc: '<br>'+req.body.matcher("Header/'CustomerParty/'Name")+
				'<br><em>quote sent</em>', ready: true}
	} else {
		throw new Error('Unhandled submitted task type: '+task.type)
	}
	req.current_user.latest_task = undefined
	res.send({status: 'ok'})
}
exports.board = function(req, res) {
	var lanes = {backoffice: [], sales: [], purchasing: [], done: []}
	WIP.forEach(function(task_id){
		var task = allTasks[task_id]
		lanes[task.for_who].push(task.board_data)
	})
	console.log('board:', lanes)
	res.send(lanes)
}
exports.tasks = function(req, res) {
	if (!req.current_user) {
		return res.send('Unauthorized', 401)
	}
	if (req.current_user.latest_task) {
		var next_task = allTasks[req.current_user.latest_task]
		return res.send( [ next_task.next_data ] )
	}
	var roles = req.current_user.roles
	console.log("user's roles:", roles)
	console.log('Q:', Q)
	console.log('WIP:', WIP)
	for (var i = 0; i < Q.length; i++) {
		var task_id = Q[i]
		var task = allTasks[task_id]
		// console.log('task_id:', task_id, 'task:', task)
		if (roles.indexOf(task.for_who) >= 0) {
			Q.splice(i, 1)
			i--
			//remove the prev_task_id task from WIP
			WIP.removeTask(task.prev_task_id)
			var next_task = generate_next_task(req, task)
			if (next_task) {
				next_task.add_event(req.current_user.email, 'receive it as next task')
				req.current_user.latest_task = next_task.id
				WIP.addTask(next_task.id)
				return res.send( [ next_task.next_data ] )
			}
		}
	}
	res.send([])
}
function generate_next_task(req, task){
	if (task.type == 'incoming fax') {
		var res = bod_transformations.ProcessFax(task.data, req.app.settings.env == 'development')
		task.add_event('system', 'generate next task')
		task.next_data = res
		task.board_data = {id: 'FAX', desc: 'processing...', ready: false}
		return task
	}
	if (task.type == 'inventory mapping customer RFQ') {
		var res = bod_transformations.ProcessRFQ(task.data)
		task.add_event('system', 'generate next task')
		task.next_data = res
		var header = task.data.DataArea.RFQ.RFQHeader
		task.board_data = {id: 'RFQ#'+header.DocumentID.ID,
			desc: '<br>'+header.CustomerParty.Name+'<br>mapping inventory...', ready: false}
		return task
	}
	if (task.type == 'supplier mapping customer RFQ') {
		var res = bod_transformations.ProcessSalesOrder(task.data)
		task.add_event('system', 'generate next task')
		task.next_data = res
		var prev = allTasks[task.prev_task_id].data
		task.board_data = {id: 'RFQ#'+prev.matcher("Header/'DocumentID/'ID"),
			desc: '<br>'+prev.matcher("Header/'CustomerParty/'Name")+
				'<br><em>mapping suppliers...</em>', ready: false}
		return task
	}
	if (task.type == 'pricing full inventory mapped customer Quote') {
		var res = bod_transformations.ProcessSalesOrder(task.data)
		task.add_event('system', 'generate next task')
		task.next_data = res
		// var header = task.data.DataArea.SalesOrder.SalesOrderHeader
		// task.board_data = {id: 'RFQ#'+header.DocumentID.ID,
		// 	desc: '<br>'+header.CustomerParty.Name, ready: true}
		return task
	}
	if (task.type == 'sending out supplier RFQ') {
		var data = task.data
		var res = bod_transformations.Sync_supplier_mapped_SalesOrder(data.data,
			data.supplier_ids[data.supplier_index])
		task.add_event('system', 'generate next task')
		task.next_data = res
		var header = data.data.DataArea.SalesOrder.SalesOrderHeader
		task.board_data = {id: 'Source SO#'+header.DocumentID.ID,
			desc: '<br>'+header.CustomerParty.Name+'<br><em>sourcing...</em>', ready: false}
		if (data.supplier_index + 1 < data.supplier_ids.length) {
			task.data.supplier_index++
			addTask(task)
		}
		task.next_data.ProcessQuote.extend({UserArea: {task_id: task.id}})
		return task
	}
	if (task.type == 'check if all supplier Quote arrived') {
		var res = bod_transformations.Process_supplier_Quote(task.data)[0]
		if (!res) return
		task.add_event('system', 'generate next task')
		task.next_data = res
		task.board_data = {id: 'asd', desc: 'qwe'}
		// var header = task.data.DataArea.SalesOrder.SalesOrderHeader
		// task.board_data = {id: 'RFQ#'+header.DocumentID.ID,
		// 	desc: '<br>'+header.CustomerParty.Name, ready: true}
		task.type = 'pricing customer Quote'
		return task
	}
	if (task.type == 'sending out customer Quote') {
		var res = bod_transformations.Sync_quoted_SalesOrder(task.data)
		task.add_event('system', 'generate next task')
		task.next_data = res
		task.board_data = {id: 'asd', desc: 'qwe'}
		// var header = task.data.DataArea.SalesOrder.SalesOrderHeader
		// task.board_data = {id: 'RFQ#'+header.DocumentID.ID,
		// 	desc: '<br>'+header.CustomerParty.Name, ready: true}
		return task
	}
	throw new Error('Unhandled task type: '+task.type)
}
