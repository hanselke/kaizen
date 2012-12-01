class window.AdminUsersController
  constructor: (@$scope,@$http) ->
    @$scope.deleteMe = @deleteMe
    @$scope.users = []
    
    @refresh()

  refresh: () =>
    @$scope.users = []
    request = @$http.get "/api/admin/users"
    request.error @$scope.errorHandler
    request.success (data, status, headers, config) =>
      @$scope.users = data.items

  deleteMe: (userId) =>
    request = @$http.delete "/api/admin/users/#{userId}"
    request.error @$scope.errorHandler
    request.success (data, status, headers, config) =>
      @refresh()

window.AdminUsersController.$inject = ['$scope',"$http"]
