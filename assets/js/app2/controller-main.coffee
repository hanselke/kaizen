humanizeTime = (time) ->
  seconds = Math.round(time % 60)
  time = (time - seconds) / 60
  minutes = Math.round(time % 60)
  time = (time - minutes) / 60
  hours = Math.round(time % 24)
  time = (time - hours) / 24
  days = Math.round(time)

  if days > 0
    return "#{days}d#{hours}h#{minutes}m#{seconds}s"
  if hours > 0
    return "#{hours}h#{minutes}m#{seconds}s"
  if minutes > 0
    return "#{minutes}m#{seconds}s"
  if seconds > 0
    return "#{seconds}s"

  return ""

class window.MainController
  constructor: (@$scope,@$http,@$location) ->
    @$scope.lane_headings = {}
    @$scope.lanes = []
    @$scope.lanes2 = []
    #@$scope.colsFromLanes = []
    #@$scope.tdFromLanes = []
    @$scope.onunhold = @onUnhold

    @refresh()


  onUnhold: (taskId) =>
    request = @$http.post "/api/tasks/#{taskId}/onunhold", {}
    request.error (data, status, headers, config) =>
      @$scope.flashMessage "Failed to activate the task - please try again"
    request.success (data, status, headers, config) =>

      @$scope.currentForm = null
      @$scope.activeTaskId = taskId

      @$scope.isBoardStateActive = !@$scope.activeTaskId

      @$location.path "/task/#{@$scope.activeTaskId}"

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
        
        for card in x.cards || []
          card.isOnHold = x.name is "onhold"
          card.totalActiveTimeAsString = humanizeTime(card.totalActiveTime / 1000)
          card.totalWaitingTimeAsString = humanizeTime(card.totalWaitingTime / 1000)

      aWidth = 0
      if data.lanes.length > 0
        aWidth = 100 / data.lanes.length


      @$scope.laneWidth = "#{aWidth}%"
      @$scope.lanes = _.map data.lanes, (x) -> x.name

      for l in data.lanes
        l.totalTimeLabel = humanizeTime(l.totalTime / 1000)
        l.totalTimeLabel = "n/a" unless l.totalTimeLabel && l.totalTimeLabel.length > 0

        l.totalActiveTimeLabel = humanizeTime(l.totalActiveTime / 1000)
        l.totalActiveTimeLabel = "n/a" unless l.totalActiveTimeLabel && l.totalActiveTimeLabel.length > 0

        l.totalWaitingTimeLabel = humanizeTime(l.totalWaitingTime / 1000)
        l.totalWaitingTimeLabel = "n/a" unless l.totalWaitingTimeLabel && l.totalWaitingTimeLabel.length > 0

      @$scope.lanes2 = data.lanes 

      ###
      for l in data.lanes 
        @$scope.lanes2.push 
          _.object {}
        _.each data.lanes, (x) =>

       _.object( _.map( data.lanes, (x) -> [x.name,x]))
      ###
      
      #@$scope.colsFromLanes = @colsFromLanes @$scope.lanes
      #@$scope.tdFromLanes = @tdFromLanes @$scope.lanes2

  ###
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
  ###

  ###
  tdFromLanes: (lanes2 = {}) =>
    res = []

    for k in _.keys(lanes2)
      lane = lanes2[k]
      res.push 
        klass : "value"
        label : humanizeTime(lane.executionTime)
      res.push 
        klass : "wait" 
        label : humanizeTime(lane.waitingTime)
    res
  ###

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
window.MainController.$inject = ['$scope',"$http","$location"]
