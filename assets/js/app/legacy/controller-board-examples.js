
function BoardExamplesController() { var that = this
  this.lane_headings = {
    customer: "Customer",
    backoffice: "Backoffice",
    sales: "Sales",
    purchasing: "Purchasing",
    done: "Done / Customer"
  }

  this.boards = [
    { name: "Example", lanes: {
      backoffice: [
        ["Quote", '#SOID Eagle Tech Oilfield', true],
        ["inQuote", '#SOID Lim Soon Supplies (3/3)', false]
      ],
      sales: [ ["RFQ", '#SOID Sophie Supplies', true] ],
      purchasing: [ ["Source", '#SOID Techlink Supplies', false] ],
      done: [ ["Quote", '#SOID Techlink Oilfields', true] ]
    }},
    { name: "Empty", lanes: {
      customer: [],
      backoffice: [ ["", "", true] ],
      sales: [],
      purchasing: [],
      done: []
    }},
    { name: "<b>1.</b> Fax arrived", lanes: {
      customer: [
        ["FAX", "in", true]
      ],
      backoffice: [],
      sales: [],
      purchasing: [],
      done: []
    }},
    { name: "<b>2.</b> Processing Fax", lanes: {
      customer: [],
      backoffice: [ ["FAX", "processing...", false] ],
      sales: [],
      purchasing: [],
      done: []
    }},
    { name: "<b>3.</b> RFQ ready", lanes: {
      customer: [],
      backoffice: [ ["RFQ#V-1009", "Sophie Supply", true] ],
      sales: [],
      purchasing: [],
      done: []
    }},
    { name: "<b>4.</b> Mapping inventory to RFQ", lanes: {
      customer: [],
      backoffice: [],
      sales: [ ["RFQ#V-1009 SO#1234", "<br>mapping inventory...<br>Sophie Supply", false] ],
      purchasing: [],
      done: []
    }},
    { name: "<b>5.</b> Inventory mapped", lanes: {
      customer: [],
      backoffice: [],
      sales: [ ["SO#1234 RFQ#V-1009", "Sophie Supply", true] ],
      purchasing: [],
      done: []
    }},
    { name: "<br><em>Scenario 1: Inventory fully mapped:</em> <b>6.</b> Pricing SO", lanes: {
      customer: [],
      backoffice: [],
      sales: [ ["RFQ#V-1009 SO#1234", "<br>pricing...<br>Sophie Supply", false] ],
      purchasing: [],
      done: []
    }},
    { name: "<b>7.</b> Quote ready", lanes: {
      customer: [],
      backoffice: [],
      sales: [ ["Quote RFQ#V-1009 SO#1234", "Sophie Supply", true] ],
      purchasing: [],
      done: []
    }},   
    { name: "<b>8.</b> Sending Quote", lanes: {
      customer: [],
      backoffice: [ ["Quote RFQ#V-1009 SO#1234", "<br>sending...<br>Sophie Supply", false] ],
      sales: [],
      purchasing: [],
      done: []
    }},   
    { name: "<b>9.</b> Quote sent", lanes: {
      customer: [],
      backoffice: [ ["Quote RFQ#V-1009 SO#1234", "Sophie Supply", true] ],
      sales: [],
      purchasing: [],
      done: []
    }},   
    { name: "<br><em>Scenario 2: Inventory NOT fully mapped:</em> <b>10.</b> Mapping suppliers to SO", lanes: {
      customer: [],
      backoffice: [],
      sales: [],
      purchasing: [ ["SO#1234 RFQ#V-1009", "<br>mapping suppliers...<br>Sophie Supply", false] ],
      done: []
    }},
    { name: "<b>11. (tom)</b> outRFQs ready", lanes: {
      customer: [],
      backoffice: [],
      sales: [],
      purchasing: [
        ["outRFQ#??? SO#1234 RFQ#V-1009", "Lim Soon Supplies", true],
        ["outRFQ#??? SO#1234 RFQ#V-1009", "Eagle Tech Oilfield", true],
        ["outRFQ#??? SO#1234 RFQ#V-1009", "Alparts Tdg Ent", true]
      ],
      done: []
    }},
    { name: "<b>11. (hansel)</b> Source SO", lanes: {
      customer: [],
      backoffice: [],
      sales: [],
      purchasing: [ ["Source SO#1234", "Sophie Supply", true] ],
      done: []
    }},
    { name: "<b>12. (hansel)</b> Sourcing SO", lanes: {
      customer: [],
      backoffice: [ ["Source SO#1234", "<br>sourcing...<br>Sophie Supply", false] ],
      sales: [],
      purchasing: [],
      done: []
    }},
    { name: "<b>13. (hansel)</b> All quotes came back", lanes: {
      customer: [],
      backoffice: [ ["Quotes SO#1234", "Sophie Supply", true] ],
      sales: [],
      purchasing: [],
      done: []
    }},
  ]
  this.$watch('lane_texts', function(){
    try { that.cards = JSON.parse(that.lane_texts)
    that.lanes = Object.keys(that.cards)
     } catch (e) {}
  })
}

BoardExamplesController.prototype = {
  set_lane_texts: function(new_lane_texts) {
    console.log('new_lanes:', new_lane_texts)
    this.lane_texts = JSON.stringify(new_lane_texts, null, "  ")
  }
}