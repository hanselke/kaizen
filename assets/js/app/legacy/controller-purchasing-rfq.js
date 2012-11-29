
function PurchasingRFQController() { var that = this
  if (this.bod) init(); else this.nextTask(init)
  function init() {
    that.salesOrder = that.bod.DataArea.SalesOrder
    that.sender = that.salesOrder.SalesOrderHeader.CustomerParty
    that.sender_country = that.COUNTRY_CODES[that.sender.Location.Address.CountryCode]
      || that.sender.Location.Address.CountryCode
    var arr = that.bod.DataArea.SupplierPartyMaster
    that.supplier_map_count = {}
    that.suppliers = Object.keys(arr).map(function(k){ that.supplier_map_count[k] = 0; return arr[k] })
    that.itemToMap = undefined
  }
}
PurchasingRFQController.prototype = {
  mapItem: function(item) {
    this.itemToMap = item
    this.$defer(function(){ $('input[name="supplier_filter"]').focus() })
  },
  connectItem: function(supplier) {
    if (!this.itemToMap) return
    //unmap the previously mapped supplier
    if (this.itemToMap.UserArea.SupplierID) { this.supplier_map_count[this.itemToMap.UserArea.SupplierID]-- }
    //map the new item
    this.itemToMap.UserArea.SupplierID = supplier.PartyIDs.ID[0]
    this.supplier_map_count[supplier.PartyIDs.ID[0]]++
    this.itemToMap = undefined
  },
  getItemClass: function(item) {
    if (this.itemToMap === item) return 'selected'
    if (item.UserArea.SupplierID) return 'mapped'
    return ''
  },
  getSupplierClass: function(supplier) {
    return this.supplier_map_count[supplier.PartyIDs.ID[0]] ? 'mapped' : ''
  },
  send: function() { var that = this
    this.$xhr('POST', '/sales', this.bod, function(code, response){
      that.$parent.$root.$emit('refresh_board_event')
      that.flash = '<h2>Supplier mapping accepted!</h2>'
      that.$location.path('/main');
    }, this.errorHandler)
  }
}