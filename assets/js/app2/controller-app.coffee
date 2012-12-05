class window.AppController
  constructor: (@$route, @$location, @$window,@$scope,@$http) ->
    @$scope.nextTask = @nextTask
    @$scope.createTask = @createTask
    @$scope.flashMessage = @flashMessage
    @$scope.errorHandler = @errorHandler
    @$scope.isInRole = @isInRole
    @$scope.toBoards = @toBoards
    @$scope.getItem = @getItem
    @$scope.setItem = @setItem
    @$scope.getCurrentTask = @getCurrentTask

    @$http.defaults.headers.post['Content-Type']='application/json'

    @$scope.currentUser = undefined
    @chat_socket = io.connect '/'
    @loadCurrentUser()

  loadCurrentUser: () =>
    request = @$http.get('/api/session')
    request.success (data, status, headers, config) =>
        @setCurrentUser data
        @$scope.currentTask = @getCurrentTask()

    request.error (data, status, headers, config) =>
        @setCurrentUser null

        #if (code != 404) that.errorHandler(code, res)
        #else that.$location.path('signin')})

  setCurrentUser: (user) =>
    
    @$scope.currentUser = user
    
    @chat_socket.emit("nick", nick: user.name) if user and user.name

  isInRole: (role) =>
    return false unless @$scope.currentUser

    _.contains @$scope.currentUser.roles || [],role

  toBoards: (cb) =>
    @$location.path "/"

  getCurrentTask: () =>
    @$scope.getItem "#{@$scope.currentUser.name}-task", null

  createTask: (cb) =>
    request = @$http.post "/api/tasks", {}
    request.error (data, status, headers, config) =>
      @$scope.flashMessage "Failed to create task"
    request.success (data, status, headers, config) =>
      @$scope.flashMessage "Task created"
      # SHould invoke refresh here / ah well

  nextTask: (cb) =>

    # Remove this in production
    ###
    @$scope.currentTask = 
      taskFormURL : "http://ec2-54-251-77-171.ap-southeast-1.compute.amazonaws.com:8080/bonita?mode=app&task=QA_Data_Entry--1.3--2--Enter_Floor_Data--ita760b542-c98b-4134-829a-b73f22b7e07a--mainActivityInstance--noLoop"
      taskUUID : "QA_Data_Entry--1.3--2--Enter_Floor_Data--ita760b542-c98b-4134-829a-b73f22b7e07a--mainActivityInstance--noLoop"
    @$location.path "/task"
    return 
    ###

    request = @$http.get "/api/tasks"
    request.error (data, status, headers, config) =>
      @$scope.flashMessage "Nothing to do at the moment"
    request.success (data, status, headers, config) =>
      @$scope.currentTask = data
      @$scope.setItem "#{@$scope.currentUser.name}-task", @$scope.currentTask

      if @$scope.currentTask
        @$location.path "/task"
      else
        @$scope.flashMessage "Nothing to do at the moment"

    ###
    processInstanceUUID = null

    for lane in window.lanesBoard || []
      for card in lane.card || []
        processInstanceUUID = card.processInstance if!processInstanceUUID

    if processInstanceUUID
      request = @$http.get "/api/tasks?procInstUUID=#{processInstanceUUID}"
      request.success (data, status, headers, config) =>
        @$scope.currentTask = data
        @$location.path "/task"

    else
      alert "There is nothing to do at the moment"
    ###

  flashMessage: (msg) =>
    alert "#{msg}"

  errorHandler: (data, status, headers, config) =>
    @flashMessage "An error occured: #{status}"

  getItem: (name, defaultValue) =>
    if localStorage && typeof(localStorage.getItem) is 'function' && name in localStorage
      return localStorage.getItem(name)
    defaultValue
  
  setItem: (name, value) =>
    if localStorage && typeof(localStorage.setItem) is 'function'
      localStorage.setItem name, value

window.AppController.$inject = ['$route', '$location', '$window','$scope',"$http"]

