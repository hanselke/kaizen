_ = require 'underscore'
async = require 'async'
winston = require 'winston'
errors = require 'some-errors'
fs = require 'fs'
xlsxToForm = require '../modules/xlsx-to-form'
stateMachinePackage = require '../modules/state-machine'
stateMachineForProcessDefinition = require './helpers/state-machine-for-process-definition'
statesForRoles = require './helpers/states-for-roles'

mongoose = require "mongoose"
ObjectId = mongoose.Types.ObjectId



module.exports = class RoutesApi


  constructor:(settings) ->
    _.extend @,settings
    throw new Error("app parameter is required") unless @app
    throw new Error("identityStore parameter is required") unless @identityStore

  setupLocals: () =>

  setupRoutes: () =>
    @app.post '/api/tasks', @createTask
    @app.get  '/api/tasks/next-task', @getNextTask
    @app.post '/api/tasks/:taskId/complete', @completeTask
    @app.post '/api/tasks/:taskId/data', @saveTaskData
    @app.get  '/api/tasks/:taskId/data', @getTaskData
    @app.get  '/api/tasks/:taskId/excel', @getExcel
    @app.post '/api/tasks/:taskId/cancel', @cancelTask
    @app.post '/api/tasks/:taskId/onhold', @onHoldTask
    @app.post '/api/tasks/:taskId/onunhold', @onUnholdTask
    @app.post '/api/tasks/:taskId/pull', @pullTask
    
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




  _stateMachineForProcessDefinitionId: (processDefinitionId, cb) =>
    @dbStore.processDefinitions.get processDefinitionId,null,true, (err,item) =>
      return next err if err
      stateMachineForProcessDefinition item, (err, sm) =>
        cb err,sm

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

    @dbStore.processDefinitions.get2 req.body.processDefinitionId,{select: '_id taskNamePrefix stateMachine'}, (err,processDefinition) =>
      return next err if err
      return next new Error("createTask - Process definition #{processDefinitionId} not found") unless processDefinition

      stateMachineForProcessDefinition processDefinition, (err, sm) =>
        return next err if err

        #@dbStore.tasks.countTasksForProcessDefinitionId req.body.processDefinitionId,{}, (err,count) =>
        @dbStore.processDefinitions.getNextTaskNumber req.body.processDefinitionId, (err,count) =>
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

    isRejected = !!req.body.isRejected

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
            taskRejected : isRejected

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


  ###
  Retrieves the next task, if any, for the current user.
  Logic goes like this:
  1. we check if the user still has an open task. If so, we return it
  2. if not, we find an open task for the states that are valid for the given role
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


      statesForRoles req.user.roles,@dbStore,(err,states) =>
        return next err if err
        @dbStore.tasks.getTaskForStates states,{}, (err,task) =>
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


  pullTask: (req,res,next) =>
    return res.json {},401 unless req.user

    @dbStore.tasks.get req.params.taskId, {}, (err,task) =>
      return next err if err
      return new Error('task not found') unless task

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
