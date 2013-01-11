_ = require 'underscore'
fs = require 'fs'
#XLSX = require 'xlsx'
#utils = XLSX.utils

xlsxParser = require '../stephen-hardy/xlsx'

module.exports = class XlsxForm
  #constructor: ->

  maxCol: =>
    @xlsx.worksheets[0].maxCol

  maxRow: =>
    @xlsx.worksheets[0].maxRow

  cell: (row,col) =>
    row = @xlsx.worksheets[0].data[row]
    return null unless row
    row[col] 

  cellValue: (row,col) =>
    cell = @cell(row,col)
    return "" unless cell && cell.value
    cell.value

  cellFormatCode: (row,col) =>
    cell = @cell(row,col)
    return "" unless cell && cell.formatCode
    cell.formatCode


  loadFromPath: (path,cb) =>
    @xlsx = null

    file = fs.readFileSync(path).toString('base64')

    @xlsx = xlsxParser(file)

    #
    # xlsx: ,"zipTime":49,"creator":"mgr.qak","lastModifiedBy":"Martin Wawrusch","created":"2011-02-02T03:13:35.000Z","modified":"2012-12-13T16:21:55.000Z","activeWorksheet":0,"processTime":17}

    console.log "HHHHHH"
    console.log @xlsx.worksheets[0].name

    console.log "MAX ROW: #{@maxRow()}"
    console.log "MAX COL: #{@maxCol()}"

    console.log "ALL: #{JSON.stringify(@xlsx)}"

    console.log "HHHHHH"
 
    for row in [0..@maxRow() - 1]
      stringRow = ""
      for col in [0..@maxCol() - 1]
        stringRow += "#{JSON.stringify(@cellValue(row,col))}."
      console.log stringRow

    ###
    try
      @xlsx = XLSX.readFile(path)
    catch e
      return cb e
    

    console.log "SHEETNAME: #{@xlsx.SheetNames[0]}"

    console.log JSON.stringify(@xlsx.Sheets[@xlsx.SheetNames[0]])
    sheetname = @xlsx.SheetNames[0]



    stringify = (val) ->
      switch val.t
        when "n"
          val.v
        when "s", "str"
          JSON.stringify val.v
        else
          throw "unrecognized type " + val.t

    sheet = @xlsx.Sheets[sheetname]

    if sheet["!ref"]
      r = utils.decode_range(sheet["!ref"])
      R = r.s.r

      while R <= r.e.r
        row = []
        C = r.s.c

        while C <= r.e.c
          val = sheet[utils.encode_cell(
            c: C
            r: R
          )]
          row.push (if val then stringify(val) else "")
          ++C
        console.log row.join(",")
        ++R
    ###
    cb null

  mergeDataIntoForm: (base64Source,data,cb) =>
    @xlsx = xlsxParser(base64Source)

    cb null,  @xlsx.base64


