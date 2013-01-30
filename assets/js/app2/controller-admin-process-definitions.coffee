class window.AdminProcessDefinitionsController
  constructor: (@$scope,@$http,@$location) ->
    @$scope.deleteMe = @deleteMe
    @$scope.editForm = @editForm
    @$scope.editLayout = @editLayout
    @$scope.edit = @edit

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

  editForm: (processDefinitionId) =>
    @$location.path "/admin/process-definitions/#{processDefinitionId}/form"

  editLayout: (processDefinitionId) =>
    @$location.path "/admin/process-definitions/#{processDefinitionId}/layout"

  edit: (processDefinitionId) =>
    @$location.path "/admin/process-definitions/#{processDefinitionId}/edit"

window.AdminProcessDefinitionsController.$inject = ['$scope',"$http","$location"]
