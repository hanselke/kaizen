
function PrintQuoteController() { var that = this
  if (this.bod) init(); else this.nextTask(init)
  function init(){
    var SO = that.bod.DataArea.SalesOrder
    var PQ = that.bod.DataArea.Quote
    that.header = SO ? SO.SalesOrderHeader : PQ.QuoteHeader
    that.lines = SO ? SO.SalesOrderLine : PQ.QuoteLine
    that.date = new Date()
    $('link').attr('href', 'css/print.css')
  }
}
PrintQuoteController.prototype = {
  back: function() {
    $('link').first().attr('href', 'css/app.css')
    if (this.bod.DataArea.SalesOrder)
      this.$location.path('/sales-quote')
    else
      this.$location.path('/backoffice-customer-quote')
    this.$window.scrollTo(0, 0)
  },
  done: function() { var that = this
    this.$xhr('POST', '/sales', this.bod, function(code, response){
      that.$parent.$root.$emit('refresh_board_event')
      that.flash = '<h2>Quote accepted!</h2>'
      that.$location.path('/main');
      $('link').first().attr('href', 'css/app.css')
    }, this.errorHandler)
  }
}
