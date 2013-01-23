class window.AdminRolesAddController
  constructor: (@$scope,@$http,@$location) ->
    @$scope.role = {}
    @$scope.create = @create

  create: (user) =>
    request = @$http.post "/api/admin/roles",user
    request.error @$scope.errorHandler
    request.success (data, status, headers, config) =>
      @$location.path '/admin/roles'
      #@$scope.flashMessage "New role created"


window.AdminRolesAddController.$inject = ['$scope',"$http","$location"]
