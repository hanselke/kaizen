class window.AdminProcessDefinitionEditController
  constructor: (@$scope,@$http,@$location,@$routeParams) ->
    @$scope.processDefinition = {}
    @$scope.update = @update
    @load @$routeParams.processDefinitionId

  load: (processDefinitionId) =>
    request = @$http.get "/api/admin/process-definitions/#{processDefinitionId}"
    request.error @$scope.errorHandler
    request.success (data, status, headers, config) =>
      _.extend @$scope.processDefinition,data


  update: (processDefinition) =>
    ###
    request = @$http.post "/api/admin/process-definitions",processDefinition
    request.error @$scope.errorHandler
    request.success (data, status, headers, config) =>
      #@$scope.processDefinitions = data.items
      @$location.path '/admin/process-definitions'
      @$scope.flashMessage "New Process Definition Created"
    ###

window.AdminProcessDefinitionEditController.$inject = ['$scope',"$http","$location","$routeParams"]
