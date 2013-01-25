HtmlWriter=  require './html-writer'

class FormAndHmtl

  createCss: (form) =>
    cssPrefix = ".xlsl-form-container "
    result = ""
    for cssClass in form.cssClasses || []
      console.log "@@@@@"
      console.log JSON.stringify(cssClass)

      result += " #{cssPrefix} .#{cssClass.name} {"
      result += "font-family:\"#{cssClass.fontName}\";" if cssClass.fontName && cssClass.fontName.length > 0
      result += "font-size:#{cssClass.fontSize};" if cssClass.fontSize
      result += "font-weight:#{cssClass.fontWeight};" if cssClass.fontWeight
      result += "font-style:#{cssClass.fontStyle};" if cssClass.fontStyle && cssClass.fontStyle.length > 0
      #result += "text-decoration:#{cssClass.textDecoration};" if cssClass.textDecoration && cssClass.textDecoration.length > 0

      result += "color:#{cssClass.fontColor};" if cssClass.fontColor && cssClass.fontColor.length > 0
      result += "text-align:#{cssClass.horizontalAlignment};" if cssClass.horizontalAlignment && cssClass.horizontalAlignment.length > 0
      result += "background:#{cssClass.backgroundColor};" if cssClass.backgroundColor && cssClass.backgroundColor.length > 0


      result += "border-top:#{cssClass.borderTop};" if cssClass.borderTop 
      result += "border-bottom:#{cssClass.borderBottom};" if cssClass.borderBottom
      result += "border-left:#{cssClass.borderLeft};" if cssClass.borderLeft
      result += "border-right:#{cssClass.borderRight};" if cssClass.borderRight

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
          if !options.isActiveInputCellCurrent(cell) 
            if options.isActiveInputCell(cell)
              writer.pushTag "span"
              writer.addAttribute "data-row", r
              writer.addAttribute "data-cell", c
              writer.addAttribute "class", "r-#{r} c-#{c}"

              writer.popTag()
            else
              writer.writeText cell.text
          else
            # Note: This is a hack right now. We need to make sure people lock forms and stuff
            writer.pushTag "input" 
            writer.addAttribute "type","text"
            writer.addAttribute "style","width:100%;height:100%;border:none;background-color:#f4f4f4"
            writer.addAttribute "data-row", r
            writer.addAttribute "data-cell", c
            writer.addAttribute "class", "r-#{r} c-#{c} excel-input"

            writer.popTag()

          writer.popTag() #td

      writer.popTag()


    writer.popTag()
    writer.popTag()
    writer.html()


module.exports = new FormAndHmtl()
