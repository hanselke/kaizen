_ = require 'underscore'
async = require 'async'
winston = require 'winston'
errors = require 'some-errors'
fs = require 'fs'
xlsxToForm = require '../modules/xlsx-to-form'
stateMachinePackage = require '../modules/state-machine'

mongoose = require "mongoose"
ObjectId = mongoose.Types.ObjectId



module.exports = class RoutesApi


  constructor:(settings,@servicesBonita) ->
    _.extend @,settings
    throw new Error("app parameter is required") unless @app
    throw new Error("bonitaTransformer parameter is required") unless @bonitaTransformer
    throw new Error("servicesBonita parameter is required") unless @servicesBonita
    throw new Error("servicesBonita.processName parameter is required") unless @servicesBonita.processName
    throw new Error("identityStore parameter is required") unless @identityStore

  setupLocals: () =>

  setupRoutes: () =>
    @app.get '/api/session', @getSession

    # TODO: Ensure that we have a user here
    @app.get '/api/board', @getBoard
    @app.get '/api/tasks/next-task', @getNextTask
    @app.post '/api/tasks', @createTask
    @app.post '/api/tasks/:taskId/complete', @completeTask
    @app.post '/api/tasks/:taskId/data', @saveTaskData
    @app.get '/api/tasks/:taskId/data', @getTaskData
    @app.get '/api/tasks/:taskId/excel', @getExcel
    @app.post '/api/tasks/:taskId/cancel', @cancelTask
    @app.post '/api/tasks/:taskId/onhold', @onHoldTask
    @app.post '/api/tasks/:taskId/onunhold', @onUnholdTask
    

    @app.get '/api/admin/tasks', @getAdminTasks
    @app.get '/api/admin/users', @getAdminUsers
    @app.post '/api/admin/users', @postAdminUsers
    @app.delete '/api/admin/users/:userId', @deleteAdminUser

    @app.get '/api/admin/roles', @getAdminRoles
    @app.post '/api/admin/roles', @postAdminRoles
    @app.delete '/api/admin/roles/:roleId', @deleteAdminRole

    # This is a hack
    @app.post '/api/admin/users/:userId/roles/:role', @addRole
    @app.delete '/api/admin/users/:userId/roles/:role', @deleteRole

    @app.get '/api/process-definitions/:processDefinitionId/form-css', @getProcessDefinitionCss
    @app.get '/api/process-definitions/:processDefinitionId/:taskId/form-html', @getProcessDefinitionHtml

    @app.put '/api/me/password', @putMePassword

  ###
  Retrieve the current session (e.g. the user that is currently logged in). 
  Returns a 404 if no session exists - e.g. no user is logged in.
  ###
  getSession: (req,res,next) =>
    return res.json {}, 404 unless req.user

    #console.log "CURRENT USER #{JSON.stringify(req.user.toRest(@baseUrl))}"
    @dbStore.tasks.getActiveTask req.user._id,{}, (err,item) =>
      return next err if err

      user = req.user.toRest(@baseUrl)
      user.activeTask = null
      if item
        user.activeTask = item.toRest @baseUrl


      @dbStore.processDefinitions.all {actor:null, offset: 0, count: 1000}, (err,result) =>
        return next err if err

        containsAny = (roleArray,checkAgainstRoles) ->
          for x in checkAgainstRoles
            return true if _.contains(roleArray,x)
          false

        result.items = _.filter result.items, (x) -> containsAny(x.createableByRoles,req.user.roles)

        user.createableTasks = _.map result.items, (x) -> {_id: x._id,name: x.name, description : x.description }

        res.json user


  getAdminRoles: (req,res,next) =>
    return res.json {}, 401 unless req.user
    @dbStore.roles.all {}, (err,pagedResultRoles) =>
      return next err if err
      res.json pagedResultRoles

  postAdminRoles: (req,res,next) =>
    return next new errors.UnprocessableEntity("name") unless req.body.name

    @dbStore.roles.create req.body, {}, (err,user) =>
      return next err if err
      res.json user

  deleteAdminRole: (req,res,next) =>
    roleId = req.params.roleId
    #console.log "DELETE USER #{userId}"
    @dbStore.roles.destroy roleId, {}, (err,item) =>
      return next err if err
      res.json {}


  getAdminUsers: (req,res,next) =>
    return res.json {}, 401 unless req.user
    @dbStore.roles.all {}, (err,rolesAsPagesResult) =>
      return next err if err
      roles = _.map rolesAsPagesResult.items || [], (x) -> x.name
      roles.push "admin" unless _.contains(roles,'admin')

      return next err if err
      @identityStore.users.all 0,200, (err,result) =>
        return next err if err
        result.roles = _.map roles, (role) -> {name : role,label : role}
        #console.log JSON.stringify(result)
        res.json result



  postAdminUsers: (req,res,next) =>
    return next new errors.UnprocessableEntity("username") unless req.body.username
    return next new errors.UnprocessableEntity("password") unless req.body.password
    req.body.roles = [] unless req.body.roles

    @identityStore.users.create req.body, (err,user) =>
      return next err if err
      res.json user

  deleteAdminUser: (req,res,next) =>
    userId = req.params.userId
    #console.log "DELETE USER #{userId}"
    @identityStore.users.destroy userId,null, (err,item) =>
      return next err if err

      res.json {}



  deleteRole: (req,res,next) =>
    userId = req.params.userId
    role = req.params.role

    #console.log "DELETE ROLE #{userId} #{role}"

    @identityStore.users.removeRoles userId,[role], (err,r,item) =>
      return next err if err

      res.json {}

  addRole: (req,res,next) =>
    userId = req.params.userId
    role = req.params.role

    #console.log "ADD ROLE #{userId} #{role}"

    @identityStore.users.addRoles userId,[role], (err,r,item) =>
      return next err if err
      res.json {}







  getAdminTasks: (req,res,next) =>
    return res.json 401,{} unless req.user

    filter = null
    if req.query.year && req.query.month && req.query.day
      try
        filter = new Date(parseInt(req.query.year),parseInt(req.query.month - 1),parseInt(req.query.day))
      catch e
        #

    console.log filter

    if filter
      @dbStore.tasks.allforDay filter,{actor:null, offset: 0, count: 200, select : '_id processDefinitionId state createdAt checkedOutByUserId name taskEnded nextState totalActiveTime totalWaitingTime'}, (err,result) =>
        return next err if err
        res.json result

    else
      @dbStore.tasks.all {actor:null, offset: 0, count: 200, select : '_id processDefinitionId state createdAt checkedOutByUserId name taskEnded nextState totalActiveTime totalWaitingTime'}, (err,result) =>
        return next err if err
        res.json result


  ###
  http://localhost:8001/api/process-definitions/5101f5620cb4645c7800000b/form-css
  ###
  getProcessDefinitionCss: (req,res,next) =>
    processDefinitionId = req.params.processDefinitionId
    @dbStore.processDefinitions.get processDefinitionId,null,true, (err,item) =>
      return next err if err

      unless item && xlsxToForm.isValidLayout(item.layout)
        res.send "p.warning-box {margin-top:50px;background-color:red;color:white;}"
        return 


      xlsxToForm.createCssFromLayoutForm item.layout,(err,css) =>
        return done err if err

        res.setHeader 'Content-Type', 'text/css'
        res.send css


  ###
  Save the task data. Format: [ {r: 0,c:0, v: 'value' }]
  ###
  saveTaskData: (req,res,next) =>
    @dbStore.tasks.get req.params.taskId, {}, (err,item) =>
      return next err if err

      for dataRow in req.body
        item.data["#{dataRow.r}-#{dataRow.c}"] = dataRow.v

      item.markModified 'data'
      item.save (err) =>
        return next err if err
        res.json 201,{}


  getTaskData: (req,res,next) =>
    @dbStore.tasks.get req.params.taskId, {}, (err,item) =>
      return next err if err

      @_stateMachineForProcessDefinitionId item.processDefinitionId, (err, sm) =>
        return next err if err

        result = {}
        result.items = []
        for key,v of item.data
          rc = key.split('-')
          result.items.push 
            r : rc[0]
            c : rc[1]
            v : v

        result.processDefinitionId = item.processDefinitionId
        result.form = sm.getFormForState(item.state)
        result.taskName = item.name
        result.taskMessage = item.message
        res.json result

  ###
  http://localhost:8001/api/tasks/50f9893de7d3a46cb000000b/excel
  ###
  getExcel: (req,res,next) =>
    return res.send 401,"Login required" unless req.user

    @dbStore.tasks.get req.params.taskId,{}, (err,task) =>
      return res.send 404, "Task not found" unless task

      @dbStore.processDefinitions.get task.processDefinitionId,null,true, (err,processDefinition) =>
        return next err if err
        return res.send 404, "Process Definition not found" unless processDefinition

        res.setHeader('Content-Type', 'text/csv')
        res.setHeader 'Content-Disposition','fileName="' + processDefinition.sourceFilename + '.csv"'

        dimensions = processDefinition.layout.dimensions
        data = task.data || {}

        buffer = ""
        for row in [dimensions.minRow .. dimensions.maxRow]
          for col in [dimensions.minCol .. dimensions.maxCol]
            buffer += "," if col > dimensions.minCol
            buffer += '"'
            v = data["#{row}-#{col}"]
            buffer += "#{v}" if v

            buffer += '"'

          buffer += "\r\n"

        res.send buffer

        ###
        xlsxToForm.mergeDataIntoForm processDefinition.sourceXlsx,task.data ,(err,data) =>

          res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
          res.setHeader 'Content-Disposition','fileName="' + processDefinition.sourceFilename + '"'
          res.setHeader 'Content-Transfer-Encoding', 'binary'
          res.setHeader 'Accept-Ranges','bytes'

          res.send data

        ###



  ###
  http://localhost:8001/api/process-definitions/50d22f260b75ca1d9000000c/taskIdhere/form-html
  ###
  getProcessDefinitionHtml: (req,res,next) =>
    editAllStates = req.query.editAllStates


    processDefinitionId = req.params.processDefinitionId
    taskId = req.params.taskId
    @dbStore.processDefinitions.get processDefinitionId,null,true, (err,item) =>
      return next err if err

      unless item && xlsxToForm.isValidLayout(item.layout)
        res.send "<p class=\"warning\">Could not read Layout Definition for process #{item.name}</p>"
        return 


      @_stateMachineForProcessDefinitionId processDefinitionId, (err, sm) =>
        return next err if err

        @dbStore.tasks.get taskId, {}, (err,task) =>
          return next err if err

          currentTaskState = sm.getExcelFieldFromState( task.state) || 'undefined' 
          console.log "CURRENT TASK STATE: #{currentTaskState}"
          options =
            editAllStates: editAllStates
            isActiveInputCell : (cell) => 
              return false unless cell.text && cell.text.length > 0
              return false unless sm.existsAsExcelField( cell.text)
              true

            isActiveInputCellCurrent : (cell) => 
              return false unless cell.text && cell.text.length > 0
              return false unless cell.text is currentTaskState
              true


          xlsxToForm.createHtmlFromLayoutForm item.layout,options,(err,html) =>
            return done err if err

            html = "#{html}"
            res.send html


  _stateMachineForProcessDefinitionId: (processDefinitionId, cb) =>
    @_stateMachineForAny cb

    ###
    @dbStore.processDefinitions.get2 processDefinitionId,{select: '_id stateMachine name'}, (err,processDefinition) =>
      return cb err if err
      return cb new Error("Process Definition #{processDefinitionId} not found.") unless processDefinition

      if !processDefinition.stateMachine || processDefinition.stateMachine.trim().length is 0
        return cb new Error("Missing state machine for process definition #{processDefinitionId}")

      smData = null
      try
        smData = JSON.parse(processDefinition.stateMachine)
      catch e
        console.log "Could not parse statemachine for #{processDefinition.name}"
        console.log processDefinition.stateMachine
        return cb new Error("Could not parse JSON State Machine for Process Defintion #{processDefinition.name}")

      sm = stateMachinePackage.stateMachine()
      sm.loadFromObject smData

      cb null,sm
    ###

  _stateMachineForAny: (cb) =>
    @dbStore.processDefinitions.getValidProcessDefinition {select: '_id stateMachine name'}, (err,processDefinition) =>
      return cb err if err
      return cb new Error("No valid process defintions found.") unless processDefinition

      smData = null
      try
        smData = JSON.parse(processDefinition.stateMachine)
      catch e
        console.log "Could not parse statemachine for #{processDefinition.name}"
        console.log processDefinition.stateMachine
        return cb new Error("Could not parse JSON State Machine for Process Defintion #{processDefinition.name}")

      sm = stateMachinePackage.stateMachine()
      sm.loadFromObject smData

      cb null,sm
 
  ###
  Create a new task.
  ###
  createTask: (req,res,next) =>
    return res.json 401,{} unless req.user
    return res.json 422,{} unless req.body.processDefinitionId
    # TODO: Check if user is authorized to create the task.

    processDefinitionId = req.body.processDefinitionId

    @dbStore.processDefinitions.get2 req.body.processDefinitionId,{select: '_id taskNamePrefix'}, (err,processDefinition) =>
      return next err if err
      return next new Error("createTask - Process definition #{processDefinitionId} not found") unless processDefinition

      @_stateMachineForProcessDefinitionId req.body.processDefinitionId, (err, sm) =>
        return next err if err

        @dbStore.tasks.countTasksForProcessDefinitionId req.body.processDefinitionId,{}, (err,count) =>
          return next err if err

          count = count + 1
          name = "#{processDefinition.taskNamePrefix || "TASK"}#{count}"

          initialState = sm.getInitialState()

          payload =
            processDefinitionId: req.body.processDefinitionId
            state: initialState
            checkedOutByUserId: req.user._id
            name : name

          @dbStore.tasks.create payload,actorId : req.user._id, (err,item) =>
            return next err if err
            item.id = item._id
            res.json item

  completeTask: (req,res,next) =>
    return res.json 401,{} unless req.user

    data = req.body.fields || {}
    message = req.body.message || ''

    @dbStore.tasks.get req.params.taskId, {}, (err,oldTask) =>
      return next err if err
      return new Error('task not found') unless oldTask

      @_stateMachineForProcessDefinitionId oldTask.processDefinitionId, (err, sm) =>
        return next err if err

        sm.getNextStateName oldTask.state,data, (err,nextState) =>
          return next err if err

          # the activeTime is whats added to the time between the last checkOutDate and now.
          totalActiveTime =  0
          if oldTask.totalActiveTime
            try
              totalActiveTime = oldTask.totalActiveTime
            catch e
              #nop
          
          if oldTask.checkedOutDate
            totalActiveTime += new Date() - oldTask.checkedOutDate
          else if oldTask.createdAt
            totalActiveTime += new Date() - oldTask.createdAt

          oldTask.timePerState = {} unless  oldTask.timePerState 
          unless oldTask.timePerState[oldTask.state]
            oldTask.timePerState[oldTask.state] = 
              totalActiveTime : 0
              totalWaitingTime : 0

          if oldTask.checkedOutDate
            oldTask.timePerState[oldTask.state].totalActiveTime += new Date() - oldTask.checkedOutDate
          else if oldTask.createdAt
            oldTask.timePerState[oldTask.state].totalActiveTime += new Date() - oldTask.createdAt

          data = 
            activeTaskUUID : null # to be deleted
            checkedOutByUserId: null
            checkedOutDate: null
            checkedInDate : new Date()
            #state: is left alone
            stateCompleted: true
            nextState: nextState
            totalActiveTime: totalActiveTime
            message : message
            timePerState : _.clone( oldTask.timePerState)

          data.taskEnded = true if nextState is "end"
            

          @dbStore.tasks.patch req.params.taskId, data, {}, (err,item) =>
            return next err if err
            res.json item

  _getActiveProcessDefinitionId: (next) =>
    @dbStore.processDefinitions.firstProcessDefinition {select: '_id'}, (err,processDefinition) =>
      return next err if err
      return next new Error("Process definition not found") unless processDefinition
      next null, processDefinition._id


  _addUsernameToTasks: (lanes, cb) =>
    @usernameMap = {} unless @usernameMap 
    @rolesMap = {} unless @rolesMap 

    unresolvedUserIds = {}

    for lane in lanes
      for card in lane.cards
        if card.userId
          card.username = @usernameMap[card.userId]
          card.roles = @rolesMap[card.userId] || []
          unresolvedUserIds[card.userId] = true unless @usernameMap[card.userId]

    if _.keys(unresolvedUserIds).length == 0 
      cb null # All done
    else

      idList = _.map _.keys(unresolvedUserIds), (x) -> new ObjectId x.toString()
      @identityStore.models.User.find({}).where('_id').in(idList).select('_id username roles').exec (err, items) =>
        return cb err if err
        items ||= []

        for item in items
          @usernameMap[item._id.toString()] = item.username 
          @rolesMap[item._id.toString()] = item.roles || []

        for lane in lanes
          for card in lane.cards
            card.username = @usernameMap[card.userId] if card.userId
            card.roles = @rolesMap[card.userId] if card.userId
        cb null

  getBoard: (req,res,next) =>
    return res.json {},401 unless req.user

    board = 
      lanes: []

    @_getActiveProcessDefinitionId (err,processDefinitionId) =>
      return res.json board if err || !processDefinitionId
      #return next err if err

      @_stateMachineForAny (err, sm) =>
        return next err if err

        ###
        board.lanes.push
          label: "On Hold"
          name: "onhold"
          order: 0

          activityDefinitions: [] # TBDeleted
          id: '' # TBDeleted
          totalTime : 0
          totalActiveTime : 0
          totalWaitingTime : 0 
          cards: []
        ###

        for state,i in sm.getSwimlanes() || []
          board.lanes.push
            label: state.label
            name: state.name
            order: i + 1

            activityDefinitions: [] # TBDeleted
            id: '' # TBDeleted
            totalTime : 0
            totalActiveTime : 0
            totalWaitingTime : 0 
            cards: []

        @dbStore.tasks.tasksForBoard {}, (err, pagedResult) =>
          return next err if err
          @dbStore.tasks.aggregatedTaskTimesForBoardPerState {}, (err,states) =>
            return next err if err

            laneMap = {}
            laneMap[lane.name] = lane for lane in board.lanes

            for task in pagedResult.items || []

              lane = laneMap[task.state]

              ###
              if task.onHold
                lane = laneMap["onhold"]
              ###

              if lane
                lane.cards.push 
                    id : task._id
                    desc : task.name || 'UNNAMED'
                    ready : task.stateCompleted
                    state : lane.name
                    totalActiveTime : task.totalActiveTime
                    totalWaitingTime: task.totalWaitingTime
                    totalTime :  task.totalActiveTime + task.totalWaitingTime
                    message: task.message || ''
                    isOnHold: task.onHold
                    updatedAt : task.updatedAt
                    userId : task.checkedOutByUserId

            for state,val of states
              lane = laneMap[state]
              if lane
                _.extend lane, val

            for lane in board.lanes
              lane.cards = _.sortBy lane.cards, (card) -> "#{card.isOnHold}-#{card.desc}"

            @_addUsernameToTasks board.lanes, (err) =>
              res.json board

  ###
  Retrieves the next task, if any, for the current user.
  Logic goes like this:
  1. we check if the user still has an open task. If so, we return up
  ###
  getNextTask: (req,res,next) =>
    return res.json {},401 unless req.user
    console.log "Retrieving task for #{req.user._id} and roles #{req.user.roles}"


    @dbStore.tasks.getActiveTask req.user.id || req.user._id,{}, (err,task) =>
      return next err if err
      if task
        task.id = task._id
        res.json 
          taskId : task._id
          activeTask : task
        console.log "Task already active - returned"
        return

      @_getActiveProcessDefinitionId (err,processDefinitionId) =>
        return next err if err

        ###
        If this task does not have a state machine we sideline it
        ###
        @_stateMachineForProcessDefinitionId processDefinitionId, (err, sm) =>
          return next err if err
          # HERE WE NEED TO TRANSFORM req.user.roles into allowed states.
          #states = ['qaChecks','shiftManagerApproval','productionManagerApproval']
          states = sm.getStatesForRoles(req.user.roles)

          @dbStore.tasks.getTaskForProcessDefinitionIdAndStates processDefinitionId,states,{}, (err,task) =>
            return next err if err
            return res.json {} unless task # No task found.

            totalWaitingTime =  0
            if task.totalWaitingTime
              try
                totalWaitingTime = task.totalWaitingTime
              catch e
                #nop
            
            if task.checkedInDate
              totalWaitingTime += new Date() - task.checkedInDate


            task.timePerState = {} unless  task.timePerState 
            unless task.timePerState[task.state]
              task.timePerState[task.state] = 
                totalActiveTime : 0
                totalWaitingTime : 0

            if task.checkedInDate
              task.timePerState[task.state].totalWaitingTime += new Date() - task.checkedInDate


            data =
              checkedOutByUserId: req.user.id || req.user._id
              activeTaskUUID: "" 
              activeActivityName: ""
              previousState: task.state
              state: task.nextState
              nextState : null
              stateCompleted: false
              checkedOutDate: new Date()
              checkedInDate : null
              totalWaitingTime : totalWaitingTime
              timePerState : _.clone( task.timePerState)

            @dbStore.tasks.patch task._id,data, actor : {actorId : req.user._id || req.user.id},  (err,item) =>
              return next err if err
              console.log "UPDATED #{JSON.stringify(item)}"

              # Now we need to update the data store, where processInstanceID = X
              # and set the active user to the current userid,
              # and set the active task to the current task id,
              # and we need to return our own task id (which is actually the process id)
              # we also need to register the time here.
              item.id = item._id
              res.json 
                taskId : item._id
                activeTask : item

  ###
  Receives a new password:
  {
    "password":"test"
    "retypePassword":"t4wt"
  }
  ###
  putMePassword: (req,res,next) =>
    return res.json {},401 unless req.user

    if req.body.password != req.body.retypePassword
      return res.json 422, {message: "Passwords must match"}

    userId = req.user.id || req.user._id;

    @identityStore.users.setPassword userId, req.body.password, actorId : userId, (err, result) =>
      return next err if err
      res.json 200, {}

  cancelTask: (req,res,next) =>
    return res.json 401,{} unless req.user

    @dbStore.tasks.get req.params.taskId, {}, (err,oldTask) =>
      return next err if err
      return new Error('task not found') unless oldTask

      if !oldTask.previousState 
        @dbStore.tasks.delete req.params.taskId, {}, (err) =>
          return next err if err
          return res.json {}
      else
        data = 
          activeTaskUUID : null # to be deleted
          checkedOutByUserId: null
          checkedOutDate: null
          checkedInDate : new Date()
          nextState : oldTask.state
          state : oldTask.previousState
          stateCompleted: true
          taskEnded : false

        @dbStore.tasks.patch req.params.taskId, data, {}, (err,item) =>
          return next err if err
          res.json item

  onHoldTask: (req,res,next) =>
    return res.json 401,{} unless req.user

    @dbStore.tasks.get req.params.taskId, {}, (err,oldTask) =>
      return next err if err
      return new Error('task not found') unless oldTask

      data = 
        onHold : true 

      @dbStore.tasks.patch req.params.taskId, data, {}, (err,item) =>
        return next err if err
        res.json item

  onUnholdTask: (req,res,next) =>
    return res.json 401,{} unless req.user

    @dbStore.tasks.get req.params.taskId, {}, (err,oldTask) =>
      return next err if err
      return new Error('task not found') unless oldTask

      data = 
        onHold : false 

      @dbStore.tasks.patch req.params.taskId, data, {}, (err,item) =>
        return next err if err
        res.json item
