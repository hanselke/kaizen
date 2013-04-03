class window.AdminBoardsEditController
  constructor: (@$scope,@$http,@$location,@$routeParams) ->
    @$scope.board = {}
    @$scope.update = @update
    @load @$routeParams.boardId

  load: (boardId) =>
    request = @$http.get "/api/admin/boards/#{boardId}"
    request.error @$scope.errorHandler
    request.success (data, status, headers, config) =>
      _.extend @$scope.board,data


  update: (board) =>
    @$scope.board= angular.copy(board)
    ###
    request = @$http 
      method : "PATCH"
      url : "/api/admin/boards/#{board._id}"
      data : board
    ###

    request = @$http.put  "/api/admin/boards/#{board._id}",board
    request.error @$scope.errorHandler
    request.success (data, status, headers, config) =>
      @$location.path '/admin/boards'
      #@$scope.flashMessage "Process Definition Update"

window.AdminBoardsEditController.$inject = ['$scope',"$http","$location","$routeParams"]
