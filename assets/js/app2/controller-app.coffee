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
    @$scope.taskCompleted = @taskCompleted

    @$scope.isBoardStateActive = false
    @$scope.isFormStateActive = false

    @$http.defaults.headers.post['Content-Type']='application/json'

    @$scope.currentUser = undefined
    @chat_socket = io.connect '/'
    @loadSession()

  loadSession: () =>
    request = @$http.get('/api/session')
    request.success (data, status, headers, config) =>
        @setCurrentUser data
        @$scope.currentTask = @getCurrentTask()

    request.error (data, status, headers, config) =>
        @setCurrentUser null

  setCurrentUser: (user) =>    
    @$scope.currentUser = user
    @updateActiveTask if user then user.activeTask else null
    @$scope.createableTasks = if user then user.createableTasks || [] else []
    
    @chat_socket.emit("nick", nick: user.name) if user and user.name

    if @$scope.activeTask
      @$location.path "/task/#{@$scope.activeTask.id}"
    ###
    else 
      @$location.path "/"
    ###

  updateActiveTask: (activeTask) =>
    @$scope.activeTask = activeTask
    @$scope.isBoardStateActive = !@$scope.activeTask
    @$scope.isFormStateActive = !!@$scope.activeTask

  taskCompleted: () =>
    if @$scope.activeTask
      taskId = @$scope.activeTask.id

      request = @$http.post "/api/tasks/#{taskId}/complete", {}
      request.error (data, status, headers, config) =>
        @$scope.flashMessage "Failed to complete task - please try again"
      request.success (data, status, headers, config) =>
        @updateActiveTask null
        @$location.path "/"
        # Flash here




  isInRole: (role) =>
    return false unless @$scope.currentUser

    _.contains @$scope.currentUser.roles || [],role

  toBoards: (cb) =>
    @$location.path "/"

  getCurrentTask: () =>
    @$scope.getItem "#{@$scope.currentUser.name}-task", null

  createTask: (processDefinitionId) =>
    request = @$http.post "/api/tasks", processDefinitionId : processDefinitionId
    request.error (data, status, headers, config) =>
      @$scope.flashMessage "Failed to create task"
    request.success (data, status, headers, config) =>
      @$scope.flashMessage "Task created #{JSON.stringify(data)}"

      data.id = data._id unless data.id
      @updateActiveTask data
      @$location.path "/task/#{@$scope.activeTask.id}"

  nextTask: (cb) =>
    # Dummy for now.
    @$location.path "/task"

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

