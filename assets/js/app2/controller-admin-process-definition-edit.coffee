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
    request = @$http 
      method : "PATCH"
      url : "/api/admin/process-definitions/#{processDefinition._id}"
      date : processDefinition
    
    request.error @$scope.errorHandler
    request.success (data, status, headers, config) =>
      @$location.path '/admin/process-definitions'
      #@$scope.flashMessage "Process Definition Update"

window.AdminProcessDefinitionEditController.$inject = ['$scope',"$http","$location","$routeParams"]
