// Generated by CoffeeScript 1.4.0
(function() {
  var HtmlWriter, _,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  _ = require('underscore');

  module.exports = HtmlWriter = (function() {

    function HtmlWriter() {
      this.html = __bind(this.html, this);

      this.popTag = __bind(this.popTag, this);

      this.writeText = __bind(this.writeText, this);

      this.addAttribute = __bind(this.addAttribute, this);

      this.pushTag = __bind(this.pushTag, this);

      this._handleNeedClosing = __bind(this._handleNeedClosing, this);
      this.tagStack = [];
      this.htmlBuffer = "";
    }

    HtmlWriter.prototype._handleNeedClosing = function() {
      if (this.needClosing) {
        this.htmlBuffer += ">";
      }
      return this.needClosing = false;
    };

    HtmlWriter.prototype.pushTag = function(tag) {
      this._handleNeedClosing();
      this.tagStack.push(tag);
      this.htmlBuffer += "<" + tag;
      return this.needClosing = true;
    };

    HtmlWriter.prototype.addAttribute = function(key, val) {
      return this.htmlBuffer += " " + key + "=\"" + val + "\" ";
    };

    HtmlWriter.prototype.writeText = function(txt) {
      this._handleNeedClosing();
      return this.htmlBuffer += _.escape(txt);
    };

    HtmlWriter.prototype.popTag = function() {
      var popped;
      this._handleNeedClosing();
      popped = this.tagStack.pop();
      return this.htmlBuffer += "</" + popped + ">";
    };

    HtmlWriter.prototype.html = function() {
      return this.htmlBuffer;
    };

    return HtmlWriter;

  })();

}).call(this);