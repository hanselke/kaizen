HtmlWriter=  require './html-writer'

class FormAndHmtl

  createHtml: (form) =>
    writer = new HtmlWriter()

    writer.pushTag "table"
    writer.pushTag "tbody"


    writer.popTag()
    writer.popTag()
    writer.html()


module.exports = new FormAndHmtl()
