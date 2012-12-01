class window.AdminUsersController
  constructor: (@$scope,@$http) ->
    @$scope.users = []
    
    @refresh()

  refresh: () =>
    request = @$http.get "/api/admin/users"
    request.error @$scope.errorHandler
    request.success (data, status, headers, config) =>
      @$scope.users = data.items


window.AdminUsersController.$inject = ['$scope',"$http"]
