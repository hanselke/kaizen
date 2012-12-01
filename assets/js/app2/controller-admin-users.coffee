class window.AdminUsersController
  constructor: (@$scope,@$http) ->
    @$scope.deleteMe = @deleteMe
    @$scope.syncToBonita = @syncToBonita
    @$scope.syncFromBonita = @syncFromBonita
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

  syncToBonita: () =>
    request = @$http.post "/api/admin/users/synctobonita", {}
    request.error @$scope.errorHandler
    request.success (data, status, headers, config) =>
      @refresh()

  syncFromBonita: () =>
    request = @$http.post "/api/admin/users/syncfrombonita", {}
    request.error @$scope.errorHandler
    request.success (data, status, headers, config) =>
      @refresh()

window.AdminUsersController.$inject = ['$scope',"$http"]
