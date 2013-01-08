_ = require 'underscore'

module.exports =  class HtmlWriter

  constructor: ->
    @tagStack = []
    @htmlBuffer = ""

  _handleNeedClosing: =>
    @htmlBuffer += ">" if @needClosing
    @needClosing = false

  pushTag: (tag) =>
    @_handleNeedClosing()
    @tagStack.push tag
    @htmlBuffer += "<#{tag}"
    @needClosing = true

  addAttribute: (key,val) =>
    @htmlBuffer += " #{key}=\"#{val}\" "


  writeText: (txt) =>
    @_handleNeedClosing()
    @htmlBuffer += _.escape(txt)


  popTag: =>
    @_handleNeedClosing()

    popped = @tagStack.pop()
    @htmlBuffer += "</#{popped}>"

  html: =>
    @htmlBuffer