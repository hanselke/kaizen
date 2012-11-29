function PrintRFQController() { var that = this
  if (this.bod) init(); else this.nextTask(init)
  function init(){
    var RFQ = that.bod.DataArea.RFQ
    that.header = RFQ.RFQHeader
    that.lines = RFQ.RFQLine
    that.date = new Date()
    $('link').attr('href', 'css/print.css')
  }
}
PrintRFQController.prototype = {
  back: function() {
    $('link').first().attr('href', 'css/app.css')
    this.$location.path('/backoffice-supplier-rfq')
    this.$window.scrollTo(0, 0)
  },
  done: function() { var that = this
    this.$xhr('POST', '/sales', this.bod, function(code, response){
      that.$parent.$root.$emit('refresh_board_event')
      that.flash = '<h2>RFQ printed!</h2>'
      that.$location.path('/main')
      $('link').first().attr('href', 'css/app.css')
    }, this.errorHandler)
  }
}
