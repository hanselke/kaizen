class window.AdminUsersAddController
  constructor: (@$scope,@$http) ->
    @$scope.user = {}
    @$scope.create = @create

  create: (user) =>
    request = @$http.post "/api/admin/users",user
    request.error @$scope.errorHandler
    request.success (data, status, headers, config) =>
      #@$scope.users = data.items
      alert 'that worked'

window.AdminUsersAddController.$inject = ['$scope',"$http"]
