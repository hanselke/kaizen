

function BackofficeSalesQuoteController(){ var that = this
  if (this.bod) init(); else this.nextTask(init)
  function init() {
    that.quote = that.bod.ProcessQuote.DataArea.Quote
    that.sender = that.quote.QuoteHeader.SupplierParty
    that.sender_country = that.COUNTRY_CODES[that.sender.Location.Address.CountryCode]
      || that.sender.Location.Address.CountryCode
  }
}