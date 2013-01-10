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
        cb null,form

  loadAndConvertVba: (pathToJson,cb) =>
    lf = new LayoutForm()

    lf.loadVbaOutputFromPath pathToJson, (err,converted) =>
      cb err, converted

  createHtmlFromLayoutForm: (layoutForm,cb) =>
      html = formAndHtml.createHtml(layoutForm)
      cb null,html

  createCssFromLayoutForm: (layoutForm,cb) =>
      css = formAndHtml.createCss(layoutForm)
      cb null,css

  loadVbaOutput: (raw,cb) =>
    lf = new LayoutForm()
    lf.loadVbaOutput raw,cb