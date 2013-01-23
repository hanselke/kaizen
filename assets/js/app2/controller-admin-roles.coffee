class window.AdminRolesController
  constructor: (@$scope,@$http,@$location) ->
    @$scope.deleteMe = @deleteMe

    @$scope.roles = []
    @refresh()

  refresh: () =>
    @$scope.processes = []
    request = @$http.get "/api/admin/roles"
    request.error @$scope.errorHandler
    request.success (data, status, headers, config) =>
      @$scope.roles = data.items

  deleteMe: (roleId) =>
    request = @$http.delete "/api/admin/roles/#{roleId}"
    request.error @$scope.errorHandler
    request.success (data, status, headers, config) =>
      @refresh()

window.AdminRolesController.$inject = ['$scope',"$http","$location"]
