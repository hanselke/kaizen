class window.AdminBoardsAddController
  constructor: (@$scope,@$http,@$location) ->
    @$scope.board = {}
    @$scope.create = @create

  create: (board) =>
    request = @$http.post "/api/admin/boards",board
    request.error @$scope.errorHandler
    request.success (data, status, headers, config) =>
      #@$scope.processDefinitions = data.items
      @$location.path '/admin/boards'
      @$scope.flashMessage "New Board Created"


window.AdminBoardsAddController.$inject = ['$scope',"$http","$location"]
