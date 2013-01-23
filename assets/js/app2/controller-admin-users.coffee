class window.AdminUsersController
  constructor: (@$scope,@$http) ->
    @$scope.deleteMe = @deleteMe
    @$scope.removeRole = @removeRole
    @$scope.addRole = @addRole

    @$scope.users = []
    @$scope.roles = []
    
    @refresh()

  refresh: () =>
    @$scope.users = []
    request = @$http.get "/api/admin/users"
    request.error @$scope.errorHandler
    request.success (data, status, headers, config) =>
      for user in data.items
        user.activeRoles = user.roles
        user.inactiveRoles = _.difference( _.map(data.roles,(x)->x.name),  user.roles)

      @$scope.users = data.items
      @$scope.roles = data.roles

  deleteMe: (userId) =>
    request = @$http.delete "/api/admin/users/#{userId}"
    request.error @$scope.errorHandler
    request.success (data, status, headers, config) =>
      @refresh()

  removeRole: (userId,role) =>
    request = @$http.delete "/api/admin/users/#{userId}/roles/#{encodeURI(role)}"
    request.error @$scope.errorHandler
    request.success (data, status, headers, config) =>
      @refresh()

  addRole: (userId,role) =>
    request = @$http.post "/api/admin/users/#{userId}/roles/#{encodeURI(role)}"
    request.error @$scope.errorHandler
    request.success (data, status, headers, config) =>
      @refresh()


window.AdminUsersController.$inject = ['$scope',"$http"]
