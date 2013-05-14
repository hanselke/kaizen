class window.AdminTasksReopenController
  constructor: (@$scope,@$http,@$location,@$routeParams) ->
    @$scope.task = 
      selectedState : 'start'
    @$scope.update = @update
    @load @$routeParams.taskId

  load: (taskId) =>
    request = @$http.get "/api/admin/tasks/#{taskId}/reopen"
    request.error @$scope.errorHandler
    request.success (data, status, headers, config) =>
      _.extend @$scope.task,data

  update: (task) =>
    @$scope.task= angular.copy(task)

    return unless task.selectedState && task.selectedState.length > 0

    request = @$http.post  "/api/admin/tasks/#{task._id}/reopen", {state : task.selectedState}
    request.error @$scope.errorHandler
    request.success (data, status, headers, config) =>
      @$location.path '/api/admin/tasks'      #

window.AdminTasksReopenController.$inject = ['$scope',"$http","$location","$routeParams"]
