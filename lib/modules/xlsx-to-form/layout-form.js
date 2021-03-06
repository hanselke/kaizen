// Generated by CoffeeScript 1.4.0
(function() {
  var FixVba, LayoutForm, fs, _,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  _ = require('underscore');

  fs = require('fs');

  FixVba = (function() {

    function FixVba(vba) {
      this.vba = vba;
      this._fixFontStyles = __bind(this._fixFontStyles, this);

      this._fontToHash = __bind(this._fontToHash, this);

      this._fixBorderAndCellStyles = __bind(this._fixBorderAndCellStyles, this);

      this._borderLineStyle = __bind(this._borderLineStyle, this);

      this._toBorderCss = __bind(this._toBorderCss, this);

      this._borderToHash = __bind(this._borderToHash, this);

      this._fixMerges = __bind(this._fixMerges, this);

      this._fixColorCodes = __bind(this._fixColorCodes, this);

      this._colToWeb = __bind(this._colToWeb, this);

      this._twoDigitString = __bind(this._twoDigitString, this);

      this.fix = __bind(this.fix, this);

    }

    FixVba.prototype.fix = function() {
      this._fixColorCodes();
      this._fixFontStyles();
      this._fixBorderAndCellStyles();
      return this._fixMerges();
    };

    FixVba.prototype._twoDigitString = function(x) {
      if (x.length === 2) {
        return x;
      }
      return "0" + x;
    };

    FixVba.prototype._colToWeb = function(col) {
      var b, g, r, res;
      if (col == null) {
        col = 0;
      }
      b = (col % 256).toString(16);
      g = ((col >> 8) % 256).toString(16);
      r = ((col >> 16) % 256).toString(16);
      return res = "#" + (this._twoDigitString(r)) + (this._twoDigitString(g)) + (this._twoDigitString(b));
    };

    FixVba.prototype._fixColorCodes = function() {
      var col, row, _i, _len, _ref, _results;
      _ref = this.vba.rows || [];
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        row = _ref[_i];
        _results.push((function() {
          var _j, _len1, _ref1, _results1;
          _ref1 = row.cells || row.cols || [];
          _results1 = [];
          for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
            col = _ref1[_j];
            col.backgroundColor = this._colToWeb(col.backgroundColor);
            col.fontColor = this._colToWeb(col.fontColor);
            if (col.borderLeft) {
              col.borderLeft.color = this._colToWeb(col.borderLeft.color);
            }
            if (col.borderRight) {
              col.borderRight.color = this._colToWeb(col.borderRight.color);
            }
            if (col.borderTop) {
              col.borderTop.color = this._colToWeb(col.borderTop.color);
            }
            if (col.borderBottom) {
              _results1.push(col.borderBottom.color = this._colToWeb(col.borderBottom.color));
            } else {
              _results1.push(void 0);
            }
          }
          return _results1;
        }).call(this));
      }
      return _results;
    };

    FixVba.prototype._fixMerges = function(col) {};

    FixVba.prototype._borderToHash = function(col) {
      if (!col.borderLeft) {
        col.borderLeft = {};
      }
      if (!col.borderborderRight) {
        col.borderRight = {};
      }
      if (!col.borderTop) {
        col.borderTop = {};
      }
      if (!col.borderBottom) {
        col.borderBottom = {};
      }
      return "" + col.backgroundColor + "-" + col.horizontalAlignment + "-" + col.borderLeft.color + "-" + col.borderLeft.lineStyle + "-" + col.borderLeft.weight + "-" + col.borderRight.color + "-" + col.borderRight.lineStyle + "-" + col.borderRight.weight + "-" + col.borderTop.color + "-" + col.borderTop.lineStyle + "-" + col.borderTop.weight + "-" + col.borderBottom.color + "-" + col.borderBottom.lineStyle + "-" + col.borderBottom.weight;
    };

    FixVba.prototype._toBorderCss = function(border) {
      var borderLineStyle;
      if (!border) {
        return "";
      }
      if (!(border.weight && border.weight >= 0)) {
        border.weight = 0;
      }
      if (border.weight > 20) {
        border.weight = 20;
      }
      if (!border.color) {
        border.color = "";
      }
      borderLineStyle = this._borderLineStyle(border.lineStyle);
      if (borderLineStyle === "none") {
        borderLineStyle = "solid";
        if (!border.color) {
          border.color = "#eee";
        }
        if (!(border.weight > 0)) {
          border.weight = 1;
        }
      }
      return "" + borderLineStyle + " " + border.weight + "px  " + border.color;
    };

    FixVba.prototype._borderLineStyle = function(ls) {
      switch (ls) {
        case 1:
          return "solid";
        case -4115:
          return 'dashed';
        case 4:
          return 'dashed';
        case 5:
          return 'dashed';
        case -4142:
          return 'none';
        case -4118:
          return "dotted";
        case -4119:
          return "double";
        case 13:
          return "dashed";
      }
      return "none";
    };

    FixVba.prototype._fixBorderAndCellStyles = function() {
      var col, cssClassName, hash, row, styleCache, styleCount, _i, _len, _ref, _results;
      styleCount = 0;
      styleCache = {};
      if (!this.vba.cssClasses) {
        this.vba.cssClasses = [];
      }
      _ref = this.vba.rows || [];
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        row = _ref[_i];
        _results.push((function() {
          var _j, _len1, _ref1, _results1;
          _ref1 = row.cells || row.cols || [];
          _results1 = [];
          for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
            col = _ref1[_j];
            hash = this._borderToHash(col);
            if (!styleCache[hash]) {
              cssClassName = "cell-" + styleCount;
              styleCount = styleCount + 1;
              styleCache[hash] = cssClassName;
              this.vba.cssClasses.push({
                name: cssClassName,
                textAlign: col.horizontalAlignment,
                backgroundColor: col.backgroundColor,
                borderLeft: this._toBorderCss(col.borderLeft),
                borderRight: this._toBorderCss(col.borderRight),
                borderTop: this._toBorderCss(col.borderTop),
                borderBottom: this._toBorderCss(col.borderBottom)
              });
            }
            col.cellCssClass = styleCache[hash];
            delete col.horizontalAlignment;
            delete col.backgroundColor;
            delete col.borderLeft;
            delete col.borderRight;
            delete col.borderTop;
            _results1.push(delete col.borderBottom);
          }
          return _results1;
        }).call(this));
      }
      return _results;
    };

    FixVba.prototype._fontToHash = function(col) {
      return "" + col.fontName + "-" + col.fontSize + "-" + col.fontBold + "-" + col.fontItalic + "-" + col.fontUnderline + "-" + col.fontColor;
    };

    FixVba.prototype._fixFontStyles = function() {
      var col, cssClassName, fontStyleCache, hash, row, styleCount, _i, _len, _ref, _results;
      styleCount = 0;
      fontStyleCache = {};
      if (!this.vba.cssClasses) {
        this.vba.cssClasses = [];
      }
      _ref = this.vba.rows || [];
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        row = _ref[_i];
        _results.push((function() {
          var _j, _len1, _ref1, _results1;
          _ref1 = row.cells || row.cols || [];
          _results1 = [];
          for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
            col = _ref1[_j];
            hash = this._fontToHash(col);
            if (!fontStyleCache[hash]) {
              cssClassName = "fnt-" + styleCount;
              styleCount = styleCount + 1;
              fontStyleCache[hash] = cssClassName;
              this.vba.cssClasses.push({
                name: cssClassName,
                fontName: col.fontName,
                fontSize: "" + col.fontSize + "pt",
                fontWeight: col.fontBold ? "700" : "400",
                fontStyle: col.fontItalic ? "italic" : "normal",
                textDecoration: col.fontUnderline ? "underline" : "none",
                color: col.fontColor
              });
            }
            col.fontCssClass = fontStyleCache[hash];
            delete col.fontName;
            delete col.fontSize;
            delete col.fontBold;
            delete col.fontItalic;
            delete col.fontUnderline;
            _results1.push(delete col.fontColor);
          }
          return _results1;
        }).call(this));
      }
      return _results;
    };

    return FixVba;

  })();

  module.exports = LayoutForm = (function() {

    function LayoutForm() {
      this.loadVbaOutput = __bind(this.loadVbaOutput, this);

      this.loadVbaOutputFromPath = __bind(this.loadVbaOutputFromPath, this);

    }

    LayoutForm.prototype.loadVbaOutputFromPath = function(pathToJson, cb) {
      var file;
      this.formData = null;
      file = fs.readFileSync(pathToJson);
      this.formData = JSON.parse(file);
      return this.loadVbaOutput(this.formData, cb);
    };

    LayoutForm.prototype.loadVbaOutput = function(obj, cb) {
      var fixVba;
      this.formData = obj;
      fixVba = new FixVba(this.formData);
      fixVba.fix();
      return cb(null, this.formData);
    };

    return LayoutForm;

  })();

}).call(this);
