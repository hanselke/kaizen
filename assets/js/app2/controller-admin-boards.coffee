class window.AdminBoardsController
  constructor: (@$scope,@$http,@$location) ->
    @$scope.deleteMe = @deleteMe
    @$scope.edit = @edit

    @$scope.boards = []
    @refresh()

  refresh: () =>
    @$scope.boards = []
    request = @$http.get "/api/admin/boards"
    request.error @$scope.errorHandler
    request.success (data, status, headers, config) =>
      @$scope.boards = data.items

  deleteMe: (boardId) =>
    request = @$http.delete "/api/admin/boards/#{boardId}"
    request.error @$scope.errorHandler
    request.success (data, status, headers, config) =>
      @refresh()

  edit: (boardId) =>
    @$location.path "/admin/boards/#{boardId}/edit"


window.AdminBoardsController.$inject = ['$scope',"$http","$location"]
