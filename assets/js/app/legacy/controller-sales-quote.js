

function SalesQuoteController() { var that = this
  if (this.bod) init(); else this.nextTask(init)
  function init(){
    var SO = that.bod.DataArea.SalesOrder
    that.header = SO.SalesOrderHeader
    that.lines = SO.SalesOrderLine
    if (!that.lines[0].UserArea || !that.lines[0].UserArea.originalPrice) {
      that.lines.forEach(function(item){
        // In case of the "Map all RFQ items to inventory" scenario, there is no UserArea
        if (!item.UserArea) item.UserArea = {}
        item.UserArea.originalPrice = item.UnitPrice.Amount
      })
      that.lines.forEach(function(item){
        item.UnitPrice.Amount = Math.round(120 * item.UnitPrice.Amount) / 100.0
      })
    }
    that.prevQuotes = [
      {created: "2011-09-02T02:25:31.552Z",
        id: 14,
        quotationValue: 145.33,
        profitMargin: 15.04,
        won: true
      },
      {created: "2011-09-04T05:15:31.552Z",
        id: 179,
        quotationValue: 98.23,
        profitMargin: 23.12,
        won: false
      },
      {created: "2011-09-05T07:15:31.552Z",
        id: 234,
        quotationValue: 274.11,
        profitMargin: 18.87,
        won: true
      },
    ]
    that.internal_discussion = [
      {process: 'Map inventory', chats: [
        {name: 'Chris', msg: 'Can i use the #600 steel pipe union for this order?', time: new Date(2011,11-1,4,19,38)},
        {name: 'Mike', msg: 'the japanese one? ok but charge him more', time: new Date(2011,11-1,5,19,45)}
      ]},
      {process: 'Quote', chats: [
        {name: 'Derrick', msg: "I'll charge him 25% okay?", time: new Date(2011,11-1,6,11,54)},
        {name: 'Mike', msg: 'mmmm sure', time: new Date(2011,11-1,7,11,55)}
      ]}
    ]
  }
}
SalesQuoteController.prototype = {
  /** Calculate the profit margin for the actual Quote, which is
  * (Total quote price / Total cost price) - 1, but displayed as percents.
  * Total cost price is based on the item prices in the inventory.*/
  computeProfitMargin: function() {
    var totalCostPrice = 0
    var totalQuotePrice = 0
    for (var i in this.lines) {
      var item = this.lines[i]
      totalCostPrice += item.Quantity * item.UserArea.originalPrice
      totalQuotePrice += item.Quantity * item.UnitPrice.Amount
    }
    return (totalQuotePrice / totalCostPrice - 1.0) * 100
  },
  confirm: function() {
    $('link').attr('href', 'css/print.css')
    this.$location.path('/print-quote')
  }
}
