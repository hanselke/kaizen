class window.AdminTasksController
  constructor: (@$scope,@$http,@$location) ->
    #@$scope.deleteMe = @deleteMe
    #@$scope.editForm = @editForm

    @$scope.tasks = []
    @refresh()

  refresh: () =>
    @$scope.processes = []
    request = @$http.get "/api/admin/tasks"
    request.error @$scope.errorHandler
    request.success (data, status, headers, config) =>
      @$scope.tasks = data.items

  ###
  deleteMe: (processDefinitionId) =>
    request = @$http.delete "/api/admin/process-definitions/#{processDefinitionId}"
    request.error @$scope.errorHandler
    request.success (data, status, headers, config) =>
      @refresh()
  ###

window.AdminTasksController.$inject = ['$scope',"$http","$location"]
