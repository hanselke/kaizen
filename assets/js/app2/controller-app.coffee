class window.AppController
  constructor: ($route, $location, $window,@$scope,@$http) ->
    $scope.currentUser = undefined
    @chat_socket = io.connect '/'

    $http.defaults.headers.post['Content-Type']='application/json'

    @loadCurrentUser()

  loadCurrentUser: () =>
    request = @$http.get('/api/session')
    request.success (data, status, headers, config) =>
        @setCurrentUser data
    request.error (data, status, headers, config) =>
        @setCurrentUser null

        #if (code != 404) that.errorHandler(code, res)
        #else that.$location.path('signin')})

  setCurrentUser: (user) =>
    
    @$scope.currentUser = user
    
    @chat_socket.emit("nick", nick: user.name) if user and user.name
