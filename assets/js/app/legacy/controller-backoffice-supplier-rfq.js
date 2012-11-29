

function BackofficeSupplierRFQController(){ var that = this
  if (this.bod) init(); else this.nextTask(init)
  function init() {
    that.docs = []
    that.docs.push({
      type: 'rfq',
      rfq: that.bod.DataArea.RFQ,
      quote: that.bod.ProcessQuote.DataArea.Quote,
      sent: 'Sent'
    })
  }
}
BackofficeSupplierRFQController.prototype = {
  phone: function(doc) {
    if (!doc.rfq.RFQHeader.SupplierParty.Contact.Communication.UserArea.Phone) {
      return this.$window.alert('Please provide phone number!')
    }
    doc.type = 'quote'
  },
  done: function(doc) {
    // make sure all items have price
    for (var i in doc.quote.QuoteLine) {
      var item = doc.quote.QuoteLine[i]
      if (!item.UnitPrice.Amount) {
        return this.$window.alert('All items should have price!')
      }
    }
    doc.type = 'sent'
    // if all quote are sent then send the bod to the backend
    var all = true
    for(var i in this.docs) {
      if (this.docs[i].type != 'sent') {
        all = false
        break
      }
    }
    if (all) {
      var that = this
      this.$xhr('POST', '/sales', that.bod.ProcessQuote, function(code, response){
        that.$parent.$root.$emit('refresh_board_event')
        that.flash = '<h2>Sourcing accepted!</h2>'
        that.$location.path('/main');
      }, this.errorHandler)
    }
  },
  printPreview: function(){
    $('link').attr('href', 'css/print.css')
    this.$location.path('/print-rfq')
    this.$window.scrollTo(0, 0)
  }
}