###
Convert an xlsx to a form for display
###

XlsxForm = require './xlsx-form'
LayoutForm = require './layout-form'
formAndHtml = require './form-and-html'

module.exports = 
  loadAndConvert: (path,cb) ->
    form = new XlsxForm()
    form.loadFromPath path, (err) =>
      
      form = {}
      html = formAndHtml.createHtml(form)
      cb null,html

  loadAndConvertVba: (pathToJson,cb) =>
    lf = new LayoutForm()

    lf.loadVbaOutputFromPath pathToJson, (err,converted) =>
      cb err, converted

