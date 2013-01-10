_ = require 'underscore'
fs = require 'fs'

class FixVba
  constructor:  (@vba) ->

  fix: =>
    @_fixColorCodes()
    @_fixFontStyles()
    @_fixBorderAndCellStyles()
    @_fixMerges()

  _twoDigitString: (x) =>
    return x if x.length is 2
    "0#{x}"

  _colToWeb: (col = 0) =>
    b = (col % 256).toString(16)
    g = ((col >> 8) % 256).toString(16)
    r = ((col >> 16) % 256).toString(16)
    res = "##{@_twoDigitString(r)}#{@_twoDigitString(g)}#{@_twoDigitString(b)}"


  _fixColorCodes: =>
    for row in @vba.rows || []
      for col in row.cells || row.cols || []
        col.backgroundColor = @_colToWeb(col.backgroundColor)
        col.fontColor = @_colToWeb(col.fontColor)
        col.borderLeft.color = @_colToWeb(col.borderLeft.color) if(col.borderLeft)
        col.borderRight.color = @_colToWeb(col.borderRight.color) if(col.borderRight)
        col.borderTop.color = @_colToWeb(col.borderTop.color) if(col.borderTop)
        col.borderBottom.color = @_colToWeb(col.borderBottom.color) if(col.borderBottom)

  _fixMerges: (col) =>
    # nop

  _borderToHash: (col) =>
    col.borderLeft = {} unless col.borderLeft
    col.borderRight = {} unless col.borderborderRight
    col.borderTop = {} unless col.borderTop
    col.borderBottom = {} unless col.borderBottom

    "#{col.backgroundColor}-#{col.horizontalAlignment}-#{col.borderLeft.color}-#{col.borderLeft.lineStyle}-#{col.borderLeft.weight}-#{col.borderRight.color}-#{col.borderRight.lineStyle}-#{col.borderRight.weight}-#{col.borderTop.color}-#{col.borderTop.lineStyle}-#{col.borderTop.weight}-#{col.borderBottom.color}-#{col.borderBottom.lineStyle}-#{col.borderBottom.weight}"

  _toBorderCss: (border) =>
    return "" unless border
    border.weight = 0 unless border.weight && border.weight >= 0
    border.weight = 20 if border.weight > 20

    border.color = "" unless border.color

    borderLineStyle = @_borderLineStyle(border.lineStyle)
    if borderLineStyle is "none"
      borderLineStyle = "solid"
      border.color = "#eee" unless border.color
      border.weight = 1 unless border.weight > 0

    "#{borderLineStyle} #{border.weight}px  #{border.color}"

  _borderLineStyle:(ls) =>
    switch ls
      when 1 then return "solid"
      when -4115 then return 'dashed'
      when 4 then return 'dashed'
      when 5 then return 'dashed'
      when -4142 then return 'none'
      when -4118 then return "dotted"
      when -4119 then return "double"
      when 13 then return "dashed"

    return "none"

  _fixBorderAndCellStyles: =>
    styleCount = 0
    styleCache = {}

    @vba.cssClasses = [] unless @vba.cssClasses

    for row in @vba.rows || []
      for col in row.cells || row.cols || []
        hash = @_borderToHash(col)
        if not styleCache[hash]
          cssClassName = "cell-#{styleCount}"
          styleCount = styleCount + 1
          styleCache[hash] = cssClassName
          @vba.cssClasses.push 
            name : cssClassName
            textAlign: col.horizontalAlignment
            backgroundColor: col.backgroundColor
            borderLeft: @_toBorderCss(col.borderLeft)
            borderRight: @_toBorderCss(col.borderRight)
            borderTop: @_toBorderCss(col.borderTop)
            borderBottom: @_toBorderCss(col.borderBottom)

        col.cellCssClass = styleCache[hash]
        delete col.horizontalAlignment
        delete col.backgroundColor
        delete col.borderLeft
        delete col.borderRight
        delete col.borderTop
        delete col.borderBottom


  _fontToHash: (col) =>
    "#{col.fontName}-#{col.fontSize}-#{col.fontBold}-#{col.fontItalic}-#{col.fontUnderline}-#{col.fontColor}"

  _fixFontStyles: =>
    styleCount = 0
    fontStyleCache = {}

    @vba.cssClasses = [] unless @vba.cssClasses

    for row in @vba.rows || []
      for col in row.cells || row.cols || []
        hash = @_fontToHash(col)
        if not fontStyleCache[hash]
          cssClassName = "fnt-#{styleCount}"
          styleCount = styleCount + 1
          fontStyleCache[hash] = cssClassName
          @vba.cssClasses.push 
            name : cssClassName
            fontName: col.fontName
            fontSize: "#{col.fontSize}pt"
            fontWeight: if col.fontBold then "700" else "400"
            fontStyle: if col.fontItalic then "italic" else "normal"
            textDecoration: if col.fontUnderline then "underline" else "none"
            color : col.fontColor


        col.fontCssClass = fontStyleCache[hash]
        delete col.fontName
        delete col.fontSize
        delete col.fontBold
        delete col.fontItalic
        delete col.fontUnderline
        delete col.fontColor

module.exports = class LayoutForm


  loadVbaOutputFromPath: (pathToJson,cb) =>
    @formData = null

    file = fs.readFileSync(pathToJson)

    @formData = JSON.parse(file)

    @loadVbaOutput @formData, cb


  loadVbaOutput: (obj,cb) =>
    @formData = obj

    fixVba = new FixVba(@formData)
    fixVba.fix()

    cb null, @formData
