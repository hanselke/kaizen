class window.AdminChangePasswordController
  constructor: (@$scope,@$http,@$location) ->
    @$scope.user = {}
    @$scope.update = @update

  update: (user) =>
    request = @$http.put "/api/me/password",user
    request.error @$scope.errorHandler
    request.success (data, status, headers, config) =>
      @$location.path '/'
      #@$scope.flashMessage "New role created"

window.AdminChangePasswordController.$inject = ['$scope',"$http","$location"]
