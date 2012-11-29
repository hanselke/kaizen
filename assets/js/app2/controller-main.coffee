class window.MainController
  constructor: (@$scope,@$http) ->
    @$scope.lane_headings = {}
    @$scope.lanes = []
    @$scope.colsFromLanes = []
    @$scope.tdFromLanes = []
    
    @refresh()

  refresh: () =>
    request = @$http.get "/api/board"
    request.error @$scope.errorHandler
    request.success (data, status, headers, config) =>
      window.lanesBoard = data.lanes
      @$scope.cards = {}
      @$scope.lane_headings = {}
      _.each data.lanes, (x) =>
        @$scope.lane_headings[x.name] = x.label
        @$scope.cards[x.name] = x.cards

      @$scope.laneWidth = "10.00%"
      @$scope.lanes = _.map data.lanes, (x) -> x.name

      @$scope.colsFromLanes = @colsFromLanes @$scope.lanes
      @$scope.tdFromLanes = @tdFromLanes @$scope.lanes

  colsFromLanes: (lanes = []) =>
    res = []

    aWidth = 0
    bWidth = 0

    if lanes.length > 0
      aWidth = 100 / lanes.length
      bWidth = aWidth / 3 * 1
      aWidth = aWidth - bWidth

    for lane in lanes
      res.push width : "#{aWidth}%" 
      res.push width : "#{bWidth}%" 
    res

  tdFromLanes: (lanes = []) =>
    res = []

    for lane in lanes
      res.push 
        klass : "value"
        label : "14 min" 
      res.push 
        klass : "wait" 
        label : "5 min"
    res


    ###
    that = this
    @chat_socket.on "msg", (data) =>
      that.chat_lines.push data
      that.$digest()

      that.$defer =>
        try
          $("#chat_window")[0].scrollTop = 9999
      

    @chat_socket.on "lines", (data) ->
      that.chat_lines = data.lines
      that.$digest()
      that.$defer ->
        try
          $("#chat_window")[0].scrollTop = 9999
    ###


###
window.MainController = (@$scope)->
  @$scopelane_headings = {}
  @$scopelanes = []
  
  @refresh()
  that = this
  @chat_socket.on "msg", (data) ->
    that.chat_lines.push data
    that.$digest()
    that.$defer ->
      try
        $("#chat_window")[0].scrollTop = 9999


  @chat_socket.on "lines", (data) ->
    that.chat_lines = data.lines
    that.$digest()
    that.$defer ->
      try
        $("#chat_window")[0].scrollTop = 9999


  @chat_socket.emit "lines", {}
window.MainController:: =
  refresh: ->
    that = this
    request = @$http.get("/api/board")
    request.success (data, status, headers, config) =>
      window.lanesBoard = res.lanes
      that.cards = {}
      that.lane_headings = {}
      _.each res.lanes, (x) ->
        that.lane_headings[x.name] = x.label
        that.cards[x.name] = x.cards

      that.laneWidth = "10.00%"
      that.lanes = _.map res.lanes, (x) -> x.name

    request.error that.errorHandler

  sendMsg: ->
    data =
      msg: @message
      name: @currentUser.name
      time: new Date()

    @chat_lines.push data
    @chat_socket.emit "msg", data
    @message = ""
    @$defer ->
      $("#chat_window")[0].scrollTop = 9999


  getClassForMsg: (line) ->
    "my-message"  if line.name is @currentUser.name
###
