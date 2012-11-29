

function BackofficeCustomerQuoteController(){ var that = this
  if (this.bod) init(); else this.nextTask(init)
  function init(){
    var PQ = that.bod.DataArea.Quote
    that.header = PQ.QuoteHeader
    that.lines = PQ.QuoteLine
  }
}
BackofficeCustomerQuoteController.prototype = {
  printPreview: function(){
    $('link').attr('href', 'css/print.css')
    this.$location.path('/print-quote')
    this.$window.scrollTo(0, 0)
  }
}