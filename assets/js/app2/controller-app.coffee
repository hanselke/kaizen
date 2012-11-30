class window.AppController
  constructor: (@$route, @$location, @$window,@$scope,@$http) ->
    @$scope.nextTask = @nextTask
    @$scope.flashMessage = @flashMessage
    @$scope.errorHandler = @errorHandler

    @$http.defaults.headers.post['Content-Type']='application/json'

    @$scope.currentUser = undefined
    @chat_socket = io.connect '/'
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


  nextTask: (cb) =>
    @$location.path "/task"
    return

    processInstanceUUID = null

    for lane in window.lanesBoard || []
      for card in lane.card || []
        processInstanceUUID = card.processInstance if!processInstanceUUID

    if processInstanceUUID
      request = @$http.get "/api/tasks?procInstUUID=#{processInstanceUUID}"
      request.success (data, status, headers, config) =>
      #request.error (data, status, headers, config) =>
      #  @setCurrentUser null

      data = 
        url : "http://spiegel.de"

      if data.url
        @$location.path "/task"
        #that.$parent.$root.$emit('refresh_board_event')

    else
      alert "There is nothing to do at the moment"

  flashMessage: (msg) =>
    alert "#{msg}"

  errorHandler: (data, status, headers, config) =>
    @flashMessage "An error occured: #{status}"

window.AppController::$inject = ['$route', '$location', '$window','$scope',"$http"]

