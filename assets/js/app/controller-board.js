function BoardController() {
  this.lane_headings = {}
  window.lanes = this.lanes = []

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
  this.$parent.$root.$on('refresh_board_event', function(){
    that.refresh()
  })
}
BoardController.prototype = {
  refresh: function() { var that = this
    this.$xhr('GET', '/api/board',
      function(code, res) { that.cards = res 
  window.lanesBoard = res.lanes

  that.lane_headings = {}
  _.each(res.lanes, function(x) {
    that.lane_headings[x.name] = x.label;
  });

  that.lanes = _.map(res.lanes, function(x) {return x.name;} );


    }, that.errorHandler )
  }
}