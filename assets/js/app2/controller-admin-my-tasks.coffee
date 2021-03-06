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

class window.AdminMyTasksController
  constructor: (@$scope,@$http,@$location) ->
    #@$scope.deleteMe = @deleteMe
    #@$scope.editForm = @editForm

    @$scope.day = (new Date()).getDate()
    @$scope.year = (new Date()).getFullYear()
    @$scope.month = (new Date()).getMonth() + 1
    @$scope.tasks = []
    $scope.$watch 'year + month + day',  =>
      @refresh()
    @refresh()

  getFilterDate: () =>
    "#{@$scope.month}/#{@$scope.day}/#{@$scope.year}"

  getValidDate: () =>
    try
      return new Date(@$scope.year,@$scope.month,@$scope.day)
    catch e
      return null
    
  refresh: () =>
    @$scope.tasks = []

    if @getValidDate()

      request = @$http.get "/api/admin/my-tasks?year=#{@$scope.year}&month=#{@$scope.month}&day=#{@$scope.day}"
      request.error @$scope.errorHandler
      request.success (data, status, headers, config) =>
        for item in data.items || []
          item.totalWaitingTimeAsString = humanizeTime(item.totalWaitingTime / 1000)
          item.totalActiveTimeAsString = humanizeTime(item.totalActiveTime / 1000)

        @$scope.tasks = data.items

  ###
  deleteMe: (processDefinitionId) =>
    request = @$http.delete "/api/admin/process-definitions/#{processDefinitionId}"
    request.error @$scope.errorHandler
    request.success (data, status, headers, config) =>
      @refresh()
  ###

window.AdminMyTasksController.$inject = ['$scope',"$http","$location"]
