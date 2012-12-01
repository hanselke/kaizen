class window.AdminUsersAddController
  constructor: (@$scope,@$http,@$location) ->
    @$scope.user = {}
    @$scope.create = @create

  create: (user) =>
    request = @$http.post "/api/admin/users",user
    request.error @$scope.errorHandler
    request.success (data, status, headers, config) =>
      #@$scope.users = data.items
      @$location.path '/admin/users'
      @$scope.flashMessage "New User Created"


window.AdminUsersAddController.$inject = ['$scope',"$http","$location"]
