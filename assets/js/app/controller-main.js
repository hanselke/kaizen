

function MainController() {
	this.lane_headings = {}
	this.lanes = []
	/*
	this.lane_headings = {
		customer: "Customer",
		backoffice: "Backoffice",
		sales: "Sales",
		billing: "Billing",
		accounting: "Accounting",
		logistics: "Logistics",
		warehouse: "Warehouse",
		purchasing: "Purchasing",
		supplier: "Supplier",
		done: "Done"
	}
	this.lanes = ['customer', 'backoffice', 'sales', 'billing', 'warehouse', 'purchasing', 'done']
	*/
	this.refresh()
	var that = this
	this.chat_socket.on('msg', function (data) {
		that.chat_lines.push(data)
		that.$digest()
		that.$defer(function(){
			try { $('#chat_window')[0].scrollTop = 9999 } catch (e) {}
		})
	})
	this.chat_socket.on('lines', function(data){
		that.chat_lines = data.lines
		that.$digest()
		that.$defer(function(){
			try { $('#chat_window')[0].scrollTop = 9999 } catch (e) {}
		})
	})
	this.chat_socket.emit('lines', {})
}
MainController.prototype = {
	refresh: function() { var that = this
		this.$xhr('GET', '/api/board',
			function(code, res) { 


	/*
	that.lane_headings = {
		customer: "Customer",
		backoffice: "Backoffice",
		sales: "Sales",
		billing: "Billing",
		accounting: "Accounting",
		logistics: "Logistics",
		warehouse: "Warehouse",
		purchasing: "Purchasing",
		supplier: "Supplier",
		done: "Done"
	}
	*/

	//that.lanes = ['customer', 'backoffice', 'sales', 'billing', 'warehouse', 'purchasing', 'done']

	window.lanesBoard = res.lanes

	that.cards = {}
	that.lane_headings = {}
	_.each(res.lanes, function(x) {
		that.lane_headings[x.name] = x.label;
		that.cards[x.name] = x.cards
	});

	that.laneWidth = "10.00%"

	that.lanes = _.map(res.lanes, function(x) {return x.name;} );
	
			}, that.errorHandler )
	},
	sendMsg: function(){
		var data = {msg: this.message, name: this.currentUser.name, time: new Date()}
		this.chat_lines.push(data)
		this.chat_socket.emit('msg', data)
		this.message = ''
		this.$defer(function(){
			$('#chat_window')[0].scrollTop = 9999
		})
	},
	getClassForMsg: function(line) {
		if (line.name == this.currentUser.name) {
			return 'my-message'
		}
	}
}

