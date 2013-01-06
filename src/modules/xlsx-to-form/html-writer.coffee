

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


  popTag: =>
    @_handleNeedClosing()

    popped = @tagStack.pop()
    @htmlBuffer += "</#{popped}>"

  html: =>
    @htmlBuffer