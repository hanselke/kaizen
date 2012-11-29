
function SalesRFQController() { var that = this
  if (this.bod) init(); else this.nextTask(init)
  function init(){
    that.salesOrder = that.bod.DataArea.SalesOrder
    that.sender = that.salesOrder.SalesOrderHeader.CustomerParty
    that.sender_country = that.COUNTRY_CODES[that.sender.Location.Address.CountryCode]
      || that.sender.Location.Address.CountryCode
    that.itemToMap = undefined
    // get out the inventory from the BOD
    var arr = that.bod.DataArea.PriceList.items
    that.map_count = {}
    that.inventory = Object.keys(arr).map(function(k){ that.map_count[k] = 0; return arr[k] })
  }
}
SalesRFQController.prototype = {
  mapItem: function(item) {
    this.itemToMap = item
    this.$defer(function(){ $('input[name="inventory_filter"]').focus() })
  },
  connectItem: function(inventoryItem) {
    if (!this.itemToMap) return
    //unmap the previously mapped inventoryItem
    if (this.itemToMap.CatalogReference.ItemID[0].ID) {
      this.map_count[this.itemToMap.CatalogReference.ItemID[0].ID]--
    }
    //map the new item
    this.itemToMap.CatalogReference.ItemID[0].ID = inventoryItem.id
    this.map_count[inventoryItem.id]++
    this.itemToMap = undefined
  },
  getItemClass: function(item) {
    if (this.itemToMap === item) return 'selected'
    if (item.CatalogReference.ItemID[0].ID) return 'mapped'
    return ''
  },
  getInventoryItemClass: function(inventoryItem) {
    return this.map_count[inventoryItem.id] ? 'mapped' : ''
  },
  done: function() {
    var that = this
    this.$xhr('POST', '/sales', this.bod, function(code, response){
      that.$parent.$root.$emit('refresh_board_event')
      that.flash = '<h2>RFQ mapping accepted!</h2>'
      that.$location.path('/main');
    }, this.errorHandler)
  }
}
