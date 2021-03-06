// Generated by CoffeeScript 1.4.0

/*
Convert an xlsx to a form for display
*/


(function() {
  var LayoutForm, XlsxForm, formAndHtml,
    _this = this;

  XlsxForm = require('./xlsx-form');

  LayoutForm = require('./layout-form');

  formAndHtml = require('./form-and-html');

  module.exports = {
    loadAndConvert: function(path, cb) {
      var form,
        _this = this;
      form = new XlsxForm();
      return form.loadFromPath(path, function(err) {
        return cb(null, form);
      });
    },
    loadAndConvertVba: function(pathToJson, cb) {
      var lf;
      lf = new LayoutForm();
      return lf.loadVbaOutputFromPath(pathToJson, function(err, converted) {
        return cb(err, converted);
      });
    },
    createHtmlFromLayoutForm: function(layoutForm, options, cb) {
      var html;
      html = formAndHtml.createHtml(layoutForm, options);
      return cb(null, html);
    },
    createCssFromLayoutForm: function(layoutForm, cb) {
      var css;
      css = formAndHtml.createCss(layoutForm);
      return cb(null, css);
    },
    loadVbaOutput: function(raw, cb) {
      var lf;
      lf = new LayoutForm();
      return lf.loadVbaOutput(raw, cb);
    },
    mergeDataIntoForm: function(sourceXlsx, formdata, cb) {
      var form;
      form = new XlsxForm();
      return form.mergeDataIntoForm(sourceXlsx, formdata, function(err, merged) {
        return cb(null, merged);
      });
    },
    /*
      Just does a simple null check for now.
    */

    isValidLayout: function(form) {
      if (!form) {
        return false;
      }
      return true;
    }
  };

}).call(this);
