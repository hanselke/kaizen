function BackofficeSalesPOController(){ var that = this
  if (this.bod) init(); else this.nextTask(init)
  function init() {
    that.po = that.bod.DataArea.PurchaseOrder
    that.po.PurchaseOrderHeader.DocumentID.ID = angular.filter.date.call(that, new Date(), 'dd.MM')
    if (that.po.PurchaseOrderLine.length == 0) that.po.PurchaseOrderLine.push({})
  }
}
BackofficeSalesPOController.prototype = {
  send: function() {
    //set LineNumber for each item
    for (var i in this.po.PurchaseOrderLine) {
      this.po.PurchaseOrderLine[i].LineNumber = parseInt(i) + 1;
      this.po.PurchaseOrderLine[i].Quantity_unitCode = null;
    }
    var that = this;
    this.$xhr('POST', '/sales', this.bod, function(code, response){
      that.$parent.$root.$emit('refresh_board_event')
      console.log('sent po:', this.bod, 'response:', response)
      if (response.status == 'ok') {
        that.flash = '<h2>Purchase order accepted!</h2>'
        that.$location.path('/')
      } else {
        that.$window.alert('Error: '+response.status+' '+response.msg)
      }
    }, this.errorHandler)
  },
}