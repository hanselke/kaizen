

function BackofficeSalesRFQController(){ var that = this
  if (this.bod) init(); else this.nextTask(init)
  function init() {
    that.image_width = 500
    that.rotate = 0
    if (!that.bod.image || that.bod.image == 'RFQ') {
      if (that.bod.demoProcessRFQ) that.bod.ProcessRFQ = that.bod.demoProcessRFQ
      that.rfq = that.bod.ProcessRFQ.DataArea.RFQ
      that.rfq.RFQHeader.DocumentID.ID = angular.filter.date.call(that, new Date(), 'dd.MM')
      if (that.rfq.RFQLine.length == 0) that.rfq.RFQLine.push({})
      that.rfq.RFQHeader.DocumentDateTime = new Date()
    } else {
      that.quote = that.bod.ProcessQuote.DataArea.Quote
    }
  }
}
BackofficeSalesRFQController.prototype = {
  addItem: function() {
    if (this.rfq.RFQLine.length > 0 && this.rfq.RFQLine[this.rfq.RFQLine.length - 1].Description) {
      this.rfq.RFQLine.push({});
    }
    this.$root.$eval();
    this.$defer(function(){
      $('input[name="item.Quantity"]').last().focus();
    })
  },
  deleteItem: function(itemIndex) {
    this.rfq.RFQLine.splice(itemIndex, 1);
    if (this.rfq.RFQLine.length == 0) {
        this.rfq.RFQLine.push({Quantity: 1});
    }
    this.$root.$eval();
    this.$defer(function(){
      $('input[name="item.Quantity"]').last().focus();
    });
  },
  send: function() {
    //set LineNumber for each item
    for (var i in this.rfq.RFQLine) {
      this.rfq.RFQLine[i].LineNumber = parseInt(i) + 1;
      this.rfq.RFQLine[i].Quantity_unitCode = null;
    }
    var that = this;
    this.$xhr('POST', '/sales', this.bod.ProcessRFQ, function(code, response){
      that.$parent.$root.$emit('refresh_board_event')
      console.log('sent rfq:', response);
      if (response.status == 'ok') {
        that.flash = '<h2>RFQ accepted!</h2>'
        that.$location.path('/main');
      } else {
        that.$window.alert('Error: '+response.status+' '+response.msg);
      }
    }, this.errorHandler);
  },
  magnify_plus: function(){
    this.image_width = Math.round(1.25 * this.image_width)
  },
  magnify_minus: function(){
    this.image_width = Math.round(0.8 * this.image_width)
  },
  upside_down: function(){
    this.rotate = this.rotate ? 0 : 180
  }
}
