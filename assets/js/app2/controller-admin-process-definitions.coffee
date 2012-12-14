class window.AdminProcessDefinitionsController
  constructor: (@$scope,@$http) ->
    @$scope.deleteMe = @deleteMe

    @$scope.processDefinitions = []
    @refresh()

  refresh: () =>
    @$scope.processes = []
    request = @$http.get "/api/admin/process-definitions"
    request.error @$scope.errorHandler
    request.success (data, status, headers, config) =>
      @$scope.processDefinitions = data.items

  deleteMe: (processDefinitionId) =>
    request = @$http.delete "/api/admin/process-definitions/#{processDefinitionId}"
    request.error @$scope.errorHandler
    request.success (data, status, headers, config) =>
      @refresh()

window.AdminProcessDefinitionsController.$inject = ['$scope',"$http"]
