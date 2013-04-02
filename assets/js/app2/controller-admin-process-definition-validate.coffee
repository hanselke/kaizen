class window.AdminProcessDefinitionValidateController
  constructor: (@$scope,@$http,@$location,@$routeParams) ->
    @$scope.validationResult = {}
    @$scope.validationAsText = ""
    @load @$routeParams.processDefinitionId

  load: (processDefinitionId) =>
    request = @$http.get "/api/process-definitions/#{processDefinitionId}/validate"
    request.error @$scope.errorHandler
    request.success (data, status, headers, config) =>


      _.extend @$scope.validationResult,data
      @$scope.validationAsText = JSON.stringify(data)

window.AdminProcessDefinitionValidateController.$inject = ['$scope',"$http","$location","$routeParams"]
