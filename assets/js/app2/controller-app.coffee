class window.AppController
  constructor: (@$route, @$location, @$window,@$scope,@$http) ->

    # Functions
    @$scope.nextTask = @nextTask
    @$scope.createTask = @createTask
    @$scope.flashMessage = @flashMessage
    @$scope.errorHandler = @errorHandler
    @$scope.isInRole = @isInRole
    @$scope.toBoards = @toBoards
    @$scope.getItem = @getItem
    @$scope.setItem = @setItem

    @$scope.isBoardStateActive = false
    #@$scope.isFormStateActive = false
    #@$scope.isFormYesNo = false

    @$http.defaults.headers.post['Content-Type']='application/json'

    @$scope.currentUser = undefined
    @chat_socket = io.connect '/'
    @loadSession()

  ###
  On startup loads the current session, and if available the active task for the logged in user.
  ###
  loadSession: () =>
    request = @$http.get('/api/session')
    request.success (data, status, headers, config) =>
        @setCurrentUser data

    request.error (data, status, headers, config) =>
        @setCurrentUser null

  setCurrentUser: (user) =>    
    @$scope.currentUser = user
    @updateActiveTask if user then user.activeTask else null
    @$scope.createableTasks = if user then user.createableTasks || [] else []
    
    @chat_socket.emit("nick", nick: user.name) if user and user.name
    @ensureCorrectScreen()

  ensureCorrectScreen: =>
    if @$location.path() is "/" or @isPathSegment('/task/')
      if !!@$scope.activeTaskId
        @$location.path "/task/#{@$scope.activeTaskId}"
      else
        @$location.path "/"

  isPathSegment: (pathRoot) =>
    p = @$location.path()
    return p.toLowerCase().substring(0, pathRoot.length) is pathRoot.toLowerCase()

  updateActiveTask: (activeTask) =>
    @$scope.activeTask = activeTask
    if activeTask
      @$scope.activeTaskId = activeTask.id
    else 
      @$scope.activeTaskId = null

    @$scope.isBoardStateActive = !@$scope.activeTaskId
    #@$scope.isFormStateActive = !!@$scope.activeTaskId






  isInRole: (role) =>
    return false unless @$scope.currentUser

    _.contains @$scope.currentUser.roles || [],role

  toBoards: (cb) =>
    @$location.path "/"


  createTask: (processDefinitionId) =>
    request = @$http.post "/api/tasks", processDefinitionId : processDefinitionId
    request.error (data, status, headers, config) =>
      @$scope.flashMessage "Failed to create task"
    request.success (data, status, headers, config) =>
      @ensureCorrectScreen()
      @$window.location.reload() 
  
  nextTask: (cb) =>
    request = @$http.get "/api/tasks/next-task"
    request.error (data, status, headers, config) =>
      #alert "GOT: #{JSON.stringify(data)}"
      @$scope.flashMessage "Nothing to do at the moment"
    request.success (data, status, headers, config) =>

      if data.taskId
        @$scope.activeTaskId = data.taskId
      else
        @$scope.activeTaskId = null

      @$scope.isBoardStateActive = !@$scope.activeTaskId
      #@$scope.isFormStateActive = !!@$scope.activeTaskId

      if !!@$scope.activeTaskId
        @$location.path "/task/#{@$scope.activeTaskId}"
      else
        @$scope.flashMessage "Nothing to do at the moment"

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

