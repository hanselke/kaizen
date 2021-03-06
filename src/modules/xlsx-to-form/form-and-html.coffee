HtmlWriter=  require './html-writer'
Encoder = require('node-html-encoder').Encoder
numericalEncoder = new Encoder('numerical')

class FormAndHmtl

  createCss: (form) =>
    cssPrefix = ".xlsl-form-container "
    result = ""
    for cssClass in form.cssClasses || []

      result += " #{cssPrefix} .#{cssClass.name} {"
      result += "font-family:\"#{cssClass.fontName}\";" if cssClass.fontName && cssClass.fontName.length > 0
      result += "font-size:#{cssClass.fontSize};" if cssClass.fontSize
      result += "font-weight:#{cssClass.fontWeight};" if cssClass.fontWeight
      result += "font-style:#{cssClass.fontStyle};" if cssClass.fontStyle && cssClass.fontStyle.length > 0
      #result += "text-decoration:#{cssClass.textDecoration};" if cssClass.textDecoration && cssClass.textDecoration.length > 0

      result += "color:#{cssClass.color};" if cssClass.color && cssClass.color.length > 0
      result += "text-align:#{cssClass.horizontalAlignment};" if cssClass.horizontalAlignment && cssClass.horizontalAlignment.length > 0
      result += "background:#{cssClass.backgroundColor};" if cssClass.backgroundColor && cssClass.backgroundColor.length > 0

      result += "border:solid 1px #ddd;" if cssClass.backgroundColor && cssClass.backgroundColor.length > 0
      ###
      result += "border-top:#{cssClass.borderTop};" if cssClass.borderTop 
      result += "border-bottom:#{cssClass.borderBottom};" if cssClass.borderBottom
      result += "border-left:#{cssClass.borderLeft};" if cssClass.borderLeft
      result += "border-right:#{cssClass.borderRight};" if cssClass.borderRight
      ###



      ###

                  borderLeft: @_toBorderCss(col.borderLeft)
                  borderRight: @_toBorderCss(col.borderRight)
                  borderTop: @_toBorderCss(col.borderTop)
                  borderBottom: @_toBorderCss(col.borderBottom)

      ###

      result += "}"

    return result

  createHtml: (form,options = {}) =>


    unless options.isActiveInputCell
      options.isActiveInputCell = (cell) -> !(cell.text && cell.text.length > 0) 
    unless options.isActiveInputCellCurrent
      options.isActiveInputCellCurrent = (cell) -> !(cell.text && cell.text.length > 0) 

    writer = new HtmlWriter()

    writer.pushTag "table"
    writer.addAttribute "class", "xslx-table"
    writer.addAttribute "cellspacing", "0"
    #writer.addAttribute "style", "border-style:none 0px transparent;background-color:transparent;background:transparent;"

    totalWidth = 0
    totalWidth += x for x in form.colWidths || []
    writer.addAttribute "width","#{totalWidth}"

    writer.pushTag "tbody"

    for x in form.colWidths || []
      writer.pushTag "col"
      writer.addAttribute "width","#{x}px"
      writer.popTag()

    for row,r in form.rows
      writer.pushTag "tr"

      height = form.rowHeights[r] || 0
      writer.addAttribute "style","height:#{height}px;"

      for cell,c in row.cells
        skipCell = false
        if cell.mergedCell && cell.mergedCell.cols
          skipCell = true if cell.mergedCell.col != c || cell.mergedCell.row != r
          # We only render cells that are not merged in, or the first ones that are merged


        if !skipCell
          writer.pushTag "td"
          if cell.mergedCell && cell.mergedCell.cols
            if cell.mergedCell.cols > 1
              writer.addAttribute "colspan", cell.mergedCell.cols 
            if cell.mergedCell.rows > 1
              writer.addAttribute "rowspan", cell.mergedCell.rows

          width = form.colWidths[c] || 0

          if !cell.mergedCell
            writer.addAttribute "width","#{width}"
            writer.addAttribute "style","width:#{width}px;"
       
          writer.addAttribute "class","#{cell.cellCssClass || ''} #{cell.fontCssClass || ''}"

          isActiveCurrent  = !!options.isActiveInputCellCurrent(cell) 
          isActive = !!options.isActiveInputCell(cell)
          editAllStates = options.editAllStates

          hasAnInput = isActiveCurrent or (isActive and editAllStates)

          if hasAnInput is true || hasAnInput is "true" # DONT EVEN ASK, THIS IS NOT A JOKE
            writer.pushTag "input" 
            writer.addAttribute "type","text"
            writer.addAttribute "style","width:100%;height:100%;border:none;"
            writer.addAttribute "data-row", r
            writer.addAttribute "data-cell", c
            writer.addAttribute "class", "r-#{r} c-#{c} excel-input"

            writer.popTag()
          else 
            if isActive
                writer.pushTag "span"
                writer.addAttribute "data-row", r
                writer.addAttribute "data-cell", c
                writer.addAttribute "class", "r-#{r} c-#{c} data-element"
                writer.popTag()
            else
              writer.pushTag "span"

              ###
              At this point the text is html encode with stuff like &#35;&#35; in it.
              We need to decode that
              ###
              if cell.value && cell.value.length > 0 && (numericalEncoder.htmlDecode(cell.value).indexOf("##")  is 0 or cell.value.indexOf("##") is 0 ) 
                writer.addAttribute "data-row", r
                writer.addAttribute "data-cell", c
                if cell.value.indexOf("##") is 0
                  writer.addAttribute "data-formula", cell.value.substring(2)
                else
                  writer.addAttribute "data-formula", numericalEncoder.htmlDecode(cell.value).substring(2)
                writer.addAttribute "class", "text-element formula-element"
                writer.writeTextPlain ""
              else
                writer.addAttribute "class", "text-element" if cell.text && cell.text.length > 0
                writer.writeTextPlain cell.text

              writer.popTag()


          writer.popTag() #td

      writer.popTag()


    writer.popTag()
    writer.popTag()
    writer.html()


module.exports = new FormAndHmtl()
