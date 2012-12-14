class window.AdminProcessDefinitionsAddController
  constructor: (@$scope,@$http,@$location) ->
    @$scope.processDefinition = {}
    @$scope.create = @create

  create: (processDefinition) =>
    request = @$http.post "/api/admin/process-definitions",processDefinition
    request.error @$scope.errorHandler
    request.success (data, status, headers, config) =>
      #@$scope.processDefinitions = data.items
      @$location.path '/admin/process-definitions'
      @$scope.flashMessage "New Process Definition Created"


window.AdminProcessDefinitionsAddController.$inject = ['$scope',"$http","$location"]
