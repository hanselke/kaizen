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

containsAnyOf = (list = [],anyOf = []) ->
  for x in anyOf
    return true if _.contains(list, x) 

  return false


class window.MainController
  constructor: (@$scope,@$http,@$location,@$compile) ->
    @$scope.lane_headings = {}
    @$scope.lanes = []
    @$scope.lanes2 = []
    #@$scope.colsFromLanes = []
    #@$scope.tdFromLanes = []
    @$scope.onunhold = @onUnhold
    @$scope.pull = @pull
    @$scope.createMenu = @createMenu

    @refresh()


  pull: (taskId) =>
    request = @$http.post "/api/tasks/#{taskId}/pull", {}
    request.error (data, status, headers, config) =>
      @$scope.flashMessage "Failed to pull the task - please try again"
    request.success (data, status, headers, config) =>

      @$scope.currentForm = null
      @$scope.activeTaskId = taskId
      @$scope.isBoardStateActive = !@$scope.activeTaskId
      @$location.path "/task/#{@$scope.activeTaskId}"

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
          #card.isOnHold = x.name is "onhold"
          card.totalActiveTimeAsString = humanizeTime(card.totalActiveTime / 1000)
          card.totalWaitingTimeAsString = humanizeTime(card.totalWaitingTime / 1000)
          card.updatedAtAsString = card.updatedAt # humanizeTime(card.updatedAt / 1000)
          console.log "CARD:ROLES: #{card.roles}"
          card.canBeActivated = !!card.roles and containsAnyOf(card.roles,@$scope.currentUser.roles || [])
          card.canBePulled = !card.userId and card.ready and !!card.allowedRolesForStateTransition and containsAnyOf(card.allowedRolesForStateTransition,@$scope.currentUser.roles || [])

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

  createMenu: () =>
    buttonRow = "<div style='width:240px;height:100%;overflow-y:scroll;'>"

    for ct in @$scope.createableTasks
      buttonRow += "<button class=\"btn\" style='margin-right:10px; margin-bottom:4px;margin-top:4px;' data-taskid=\"#{ct._id}\" ng:click='createTask(\"#{ct._id}\")'>#{ct.name}</button>"
    buttonRow += "</div>" 
    #button.btn(ng:click='createTask(item._id)',ng:repeat='item in createableTasks') Create {{item.name}} Task


    if ! @popupCreateMenu
      $('.action-create-task-menu').popover
        html : true
        placement : 'top'
        title: 'Create a New Task'
        content: @$compile(buttonRow)(@$scope)
      @popupCreateMenu = true

      $('.action-create-task-menu').popover('show')



window.MainController.$inject = ['$scope',"$http","$location","$compile"]
