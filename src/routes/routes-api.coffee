_ = require 'underscore'
async = require 'async'
winston = require 'winston'
errors = require 'some-errors'
fs = require 'fs'
xlsxToForm = require '../modules/xlsx-to-form'
stateMachinePackage = require '../modules/state-machine'

module.exports = class RoutesApi

  constructor:(settings,@servicesBonita) ->
    _.extend @,settings
    throw new Error("app parameter is required") unless @app
    throw new Error("bonitaClient parameter is required") unless @bonitaClient
    throw new Error("bonitaTransformer parameter is required") unless @bonitaTransformer
    throw new Error("servicesBonita parameter is required") unless @servicesBonita
    throw new Error("servicesBonita.processName parameter is required") unless @servicesBonita.processName

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

    @app.get '/api/admin/tasks', @getAdminTasks
    @app.get '/api/admin/users', @getAdminUsers
    @app.post '/api/admin/users', @postAdminUsers
    @app.delete '/api/admin/users/:userId', @deleteAdminUser
    @app.post '/api/admin/users/synctobonita',@syncToBonita
    @app.post '/api/admin/users/syncfrombonita',@syncFromBonita

    # This is a hack
    @app.post '/api/admin/users/:userId/roles/:role', @addRole
    @app.delete '/api/admin/users/:userId/roles/:role', @deleteRole

    @app.get '/api/admin/process-definitions', @getAdminProcessDefinitions
    @app.post '/api/admin/process-definitions', @postAdminProcessDefinitions
    @app.delete '/api/admin/process-definitions/:processDefinitionId', @deleteAdminProcessDefinition
    @app.get '/api/admin/process-definitions/:processDefinitionId', @getAdminProcessDefinition
    @app.post '/api/admin/process-definitions/:processDefinitionId', @uploadAdminProcessDefinition
    @app.post '/api/admin/process-definitions/:processDefinitionId/layout', @uploadAdminProcessDefinitionLayout
    @app.get '/api/process-definitions/:processDefinitionId/form-css', @getProcessDefinitionCss
    @app.get '/api/process-definitions/:processDefinitionId/:taskId/form-html', @getProcessDefinitionHtml


  ###
  Retrieve the current session (e.g. the user that is currently logged in). 
  Returns a 404 if no session exists - e.g. no user is logged in.
  ###
  getSession: (req,res) =>
    return res.json {}, 404 unless req.user

    #console.log "CURRENT USER #{JSON.stringify(req.user.toRest(@baseUrl))}"
    @dbStore.tasks.getActiveTask req.user._id,{}, (err,item) =>
      return next err if err

      user = req.user.toRest(@baseUrl)
      user.activeTask = null
      if item
        user.activeTask = item.toRest @baseUrl


      @dbStore.processDefinitions.all {actor:null, offset: 0, count: 200}, (err,result) =>
        return next err if err

        user.createableTasks = _.map result.items, (x) -> {_id: x._id,name: x.name, description : x.description }

        res.json user



  ###
  Purpose is to retrieve the next eligible task for a user.
  Scenario:
    1. curl -X POST -d 'options=user:jack' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: application/xml' -H 'Authorization: Basic cmVzdHVzZXI6cmVzdGJwbQ=='  http://ec2-54-251-77-171.ap-southeast-1.compute.amazonaws.com:8080/bonita-server-rest/API/queryRuntimeAPI/getOneTask/READY
    2. curl -X POST -d 'options=user:jack' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: application/xml' -H 'Authorization: Basic cmVzdHVzZXI6cmVzdGJwbQ=='  http://ec2-54-251-77-171.ap-southeast-1.compute.amazonaws.com:8080/bonita-server-rest/API/runtimeAPI/executeTask/QA_Data_Entry--1.51--7--Assign_enter_floor_data--it079eb8be-05f5-473e-805f-7e5ad655ae26--mainActivityInstance--noLoop/true
    3. curl -X POST -d 'options=user:jack' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: application/xml' -H 'Authorization: Basic cmVzdHVzZXI6cmVzdGJwbQ=='  http://ec2-54-251-77-171.ap-southeast-1.compute.amazonaws.com:8080/bonita-server-rest/API/queryRuntimeAPI/getTask/QA_Data_Entry--1.51--7--Assign_enter_floor_data--it079eb8be-05f5-473e-805f-7e5ad655ae26--mainActivityInstance--noLoop
    4. curl -X POST -d 'options=user:jack' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: application/xml' -H 'Authorization: Basic cmVzdHVzZXI6cmVzdGJwbQ=='  http://ec2-54-251-77-171.ap-southeast-1.compute.amazonaws.com:8080/bonita-server-rest/API/queryRuntimeAPI/getOneTaskByProcessInstanceUUIDAndActivityState/QA_Data_Entry--1.51--7/READY
    5. curl -X POST -d 'options=user:jack' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: application/xml' -H 'Authorization: Basic cmVzdHVzZXI6cmVzdGJwbQ=='  http://ec2-54-251-77-171.ap-southeast-1.compute.amazonaws.com:8080/bonita-server-rest/API/runtimeAPI/startTask/QA_Data_Entry--1.51--7--_1_Enter_Floor_Data--it079eb8be-05f5-473e-805f-7e5ad655ae26--mainActivityInstance--noLoop/true

  ###



  getTasksXXX: (req,res,next) =>
    return res.json {},401 unless req.user

    ###
    Obtain one eligible task
    ###
    @bonitaClient.queryRuntime.getOneTask "READY",req.user.username,null, (err,taskList) =>
      console.log "------1"
      console.log JSON.stringify(taskList)
      console.log "------1"

      return next err if err
      
      firstTaskUUID = taskList?.value
      
      if firstTaskUUID
        ###
        This is most likely an assign task. So we execute it and assign it to the current user
        ###
        @bonitaClient.runtime.executeTask firstTaskUUID,true, req.user.username,opts = {},(err) =>
          console.log "------2"
          console.log "EXECUTE TASK"
          console.log "------2"
          return next err if err
          ###
          # Now we need to retrieve the process instance id.
          ###
          # "admin"
          @bonitaClient.queryRuntime.getTask firstTaskUUID,req.user.username,{}, (err,t) =>
            return next err if err
            console.log "------3"
            console.log JSON.stringify(t)
            console.log "------3"

            processInstanceId = t?.instanceUUID?.value
            return res.json {} unless processInstanceId

            ### 
            Now we retrieve a list of possible task states
            ###
            @bonitaClient.queryRuntime.getOneTaskByProcessInstanceUUIDAndActivityState processInstanceId,"READY",req.user.username,{}, (err,nextTask) =>
              console.log "------4"
              console.log JSON.stringify(nextTask)
              console.log "------4"

              taskUUID = nextTask?.value

              #"admin"
              #@bonitaClient.runtime.startTask taskUUID,true,req.user.username,{}, (err) =>
              @bonitaClient.runtime.assignTask taskUUID,req.user.username,req.user.username,{}, (err) =>
 
                console.log "------5"
                console.log "ASSIGN"
                console.log "------5"
                result = @bonitaTransformer.toNextAction taskUUID,@servicesBonita.baseUrl
                res.json result
      else
        res.json {}


  getAdminUsers: (req,res,next) =>
    return res.json {}, 401 unless req.user
    @bonitaClient.identity.getAllRoles  "admin",{}, (err,roles) =>
      return next err if err
      @identityStore.users.all 0,100, (err,result) =>
        return next err if err
        result.roles = _.map roles.Role, (x) -> {name : x.name,label : x.label}
        #console.log JSON.stringify(result)
        res.json result


  _addRolesToBonita: (username,roles = [],cb) =>
    return cb null unless roles.length > 0

    addRole = (role,cb) =>
      winston.info "Adding role #{role} to #{username}"
      @bonitaClient.identity.addRoleToUser username, role,"admin",{},(err) =>
        winston.error "Failed adding role #{role} to #{username} - Check if role exists" if err
        cb null

    async.forEach roles ,addRole, cb

  postAdminUsers: (req,res,next) =>
    return next new errors.UnprocessableEntity("username") unless req.body.username
    return next new errors.UnprocessableEntity("password") unless req.body.password
    req.body.roles = [] unless req.body.roles

    @identityStore.users.create req.body, (err,user) =>
      return next err if err
      @bonitaClient.identity.addUser req.body.username,req.body.password,"admin",null, (err,u) =>
        return next err if err
        @_addRolesToBonita req.body.username,req.body.roles, (err) =>
          res.json user

  deleteAdminUser: (req,res,next) =>
    userId = req.params.userId
    #console.log "DELETE USER #{userId}"
    @identityStore.users.destroy userId,null, (err,item) =>
      return next err if err

      if item      
        @bonitaClient.identity.removeUser item.username,"admin",null, (err,u) =>
          #return next err if err
          res.json {}
      else
        res.json {}


  syncToBonita: (req,res,next) =>
    @identityStore.users.all 0,100, (err,result) =>
      winston.error JSON.stringify(err) if err
      return next err if err
      {items} = result

      createUserInBonita = (user,cb) =>
        @bonitaClient.identity.addUser user.username,"test1234","admin",null, (err,u) =>
          cb null

      handleRoles = (user,cb) =>
        @_addRolesToBonita user.username,user.roles, (err) =>
          cb null

      async.forEach items || [], createUserInBonita, (err) =>
        async.forEach items || [], handleRoles, (err) =>
          res.json {}

  syncFromBonita: (req,res,next) =>
    @bonitaClient.identity.getAllUsers  "admin",{}, (err,users) =>
      loadRoles = (user,cb) =>
        @bonitaClient.identity.getUserRoles user.username,"admin", {}, (err,roles) =>
          #console.log "GETUSERROLES: #{user.username} ==> #{JSON.stringify(roles)}"

          if roles && roles.Role && _.isArray( roles.Role)
            roles = roles.Role
          else if roles && roles.Role
            roles = [roles.Role]
          else
            roles = []

          roles = _.map roles, (x) -> x.name

          console.log "---> #{roles}"
          ###
          {}
          GETUSERROLES: hansel ==> {"Role":{"description":{},"dbid":"0","uuid":"d964abec-6bda-4367-a4b1-0bbe42bc2c08","name":"shift manager","label":"Shift Manager"}}
          GETUSERROLES: james ==> {"Role":[{"description":"The admin role","dbid":"0","uuid":"994e325b-cc4d-46b5-bc6d-7a9403d926bc","name":"admin","label":"Admin"},{"description":{},"dbid":"0","uuid":"a0f300cc-449
          ###

          @identityStore.users.patch user.username, roles : roles, null, (err) =>
            cb()

      createOrUpdate = (user,cb) =>
        #console.log user.username
        @identityStore.users.getByName user.username, (err,item) =>
          return cb null if err || item

          data = 
            username : user.username
            password : 'bpm'
            primaryEmail : "#{user.uuid}@x.com"

          @identityStore.users.create data, (err,item) =>
            winston.error "ERROR: #{err}" if err
            cb null

      async.forEach users.User || [], createOrUpdate, (err) =>
        async.forEach users.User || [], loadRoles, (err) =>
          res.json {}

  deleteRole: (req,res,next) =>
    userId = req.params.userId
    role = req.params.role

    #console.log "DELETE ROLE #{userId} #{role}"

    @identityStore.users.removeRoles userId,[role], (err,r,item) =>
      return next err if err

      if item      
        @bonitaClient.identity.removeRoleFromUser item.username,role,"admin",null, (err,u) =>
          #return next err if err
          res.json {}
      else
        res.json {}

  addRole: (req,res,next) =>
    userId = req.params.userId
    role = req.params.role

    #console.log "ADD ROLE #{userId} #{role}"

    @identityStore.users.addRoles userId,[role], (err,r,item) =>
      return next err if err

      if item      
        @bonitaClient.identity.addRoleToUser item.username,role,"admin",null, (err,u) =>
          #return next err if err
          res.json {}
      else
        res.json {}







  getAdminTasks: (req,res,next) =>
    return res.json 401,{} unless req.user
    @dbStore.tasks.all {actor:null, offset: 0, count: 200}, (err,result) =>
      return next err if err
      res.json result

  getAdminProcessDefinitions: (req,res,next) =>
    return res.json 401,{} unless req.user
    @dbStore.processDefinitions.all {actor:null, offset: 0, count: 200}, (err,result) =>
      return next err if err
      res.json result

 
  postAdminProcessDefinitions: (req,res,next) =>
    @dbStore.processDefinitions.create req.body,actorId : req.user._id, (err,item) =>
      res.json item

  deleteAdminProcessDefinition: (req,res,next) =>
    processDefinitionId = req.params.processDefinitionId
    @dbStore.processDefinitions.destroy processDefinitionId,null,true, (err,item) =>
      return next err if err
      res.json {}


  getAdminProcessDefinition: (req,res,next) =>
    processDefinitionId = req.params.processDefinitionId
    @dbStore.processDefinitions.get processDefinitionId,null,true, (err,item) =>
      return next err if err

      hasSource = item.sourceXlsx && item.sourceXlsx.length >0
      hasLayout = item.layout && _.keys(item.layout).length > 0
      delete item.sourceXlsx
      delete item.layout

      item = item.toJSON()
      item.hasSource = hasSource
      item.hasLayout = hasLayout

      res.json item

  uploadAdminProcessDefinition: (req,res,next) =>
    processDefinitionId = req.params.processDefinitionId

    file = req.files.file
    return next new Error("No file present") unless file


    fs.readFile file.path, 'utf8', (err, content) =>
      return next err if err

      base64Content = new Buffer(content).toString('base64')

      data = 
        sourceXlsx: base64Content
        sourceSize: file.size
        sourceFilename: file.name
        sourceType: file.type
      @dbStore.processDefinitions.patch processDefinitionId,data ,null,true, (err,item) =>
        return next err if err
        res.json {}

  uploadAdminProcessDefinitionLayout: (req,res,next) =>
    processDefinitionId = req.params.processDefinitionId

    file = req.files.file
    return next new Error("No file present") unless file

    fs.readFile file.path, 'utf8', (err, content) =>
      return next err if err

      parsedJson = null
      try
        parsedJson= JSON.parse content
      catch e
        return next new Error('Invalid JSON') unless parsedJson
      
      xlsxToForm.loadVbaOutput parsedJson, (err,converted) =>
        return next err if err

        @dbStore.processDefinitions.saveLayout processDefinitionId,converted, (err,item) =>
          return next err if err
          res.json {}

  ###
  http://localhost:8001/api/process-definitions/50d22f260b75ca1d9000000c/form-css
  ###
  getProcessDefinitionCss: (req,res,next) =>
    processDefinitionId = req.params.processDefinitionId
    @dbStore.processDefinitions.get processDefinitionId,null,true, (err,item) =>
      return next err if err

      layout1Path = "#{__dirname}/../../test/fixtures/form1-layout-raw.json"

      xlsxToForm.loadAndConvertVba layout1Path, (err,converted) =>
        return done err if err
        xlsxToForm.createCssFromLayoutForm converted,(err,css) =>
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
 
        console.log "getTaskData"
        console.log JSON.stringify(result)
        console.log "getTaskData--"
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
    processDefinitionId = req.params.processDefinitionId
    taskId = req.params.taskId
    @dbStore.processDefinitions.get processDefinitionId,null,true, (err,item) =>
      return next err if err

      @_stateMachineForProcessDefinitionId processDefinitionId, (err, sm) =>
        return next err if err

        @dbStore.tasks.get taskId, {}, (err,task) =>
          return next err if err

          console.log "TASK NAME: #{task.activeActivityName}"


          currentTaskState = sm.getExcelFieldFromState( task.state) || 'undefined' 

          options = 
            isActiveInputCell : (cell) => 
              return false unless cell.text && cell.text.length > 0
              return false unless cell.text is 'floor' or cell.text is 'shift manager' or cell.text is 'production manager'
              true

            isActiveInputCellCurrent : (cell) => 
              return false unless cell.text && cell.text.length > 0
              return false unless cell.text is currentTaskState
              true


          xlsxToForm.createHtmlFromLayoutForm item.layout,options,(err,html) =>
            return done err if err

            html = "#{html}"
            res.send html

  ###
  NEW CODE
  ###
  smData = 
    initialState: 'qaChecks'
    states:
      end: 
        hideFromlane: true
      qaChecks: 
        label: "QA Checks"
        hideFromlane: false
        allowedRoles: ['floor','admin']
        formToShow: null
        transitionToNextState: "shiftManagerApproval"
        excelField: 'floor'
      shiftManagerApproval:
        label: "Shift Manager Approval"
        hideFromlane: false
        allowedRoles: ['shiftManager','admin']
        formToShow: 'approveFloor'
        transitionToNextState:
          fn: "function(task,data,options) { return data.approvedByShiftManager ? \"productionManagerApproval\" : \"qaChecks\"};"
        excelField: 'shift manager'
      productionManagerApproval:
        label: "Production Manager Approval"
        hideFromlane: false
        allowedRoles: ['productionManager','admin']
        formToShow: 'approveShift'
        transitionToNextState: 
          fn: "function(task,data,options) { return data.approvedByProductionManager ? \"end\" : \"qaChecks\"};"
        excelField: 'production manager'
    forms:
      approveFloor: 
        fields:
          formCompleted:
            type: 'yesNoButton'
            labels: ['Process Ok', 'Process Fail']
            field: 'approvedByShiftManager'
            completesTask: true
      approveShift: 
        fields:
          formCompleted:
            type: 'yesNoButton'
            field: 'approvedByProductionManager'
            labels: ['Process Ok', 'Process Fail']
            completesTask: true

  _stateMachineForProcessDefinitionId: (processDefinitionId, cb) =>
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

    @dbStore.processDefinitions.get2 req.body.processDefinitionId,{select: '_id,taskNamePrefix'}, (err,processDefinition) =>
      return next err if err
      return next new Error("process defintion not found") unless processDefinition

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
    console.log "GOT THIS"
    console.log JSON.stringify(req.body)
    console.log "GOT THIS---"

    data = req.body.fields || {}

    @dbStore.tasks.get req.params.taskId, {}, (err,oldTask) =>
      return next err if err
      return new Error('task not found') unless oldTask

      @_stateMachineForProcessDefinitionId oldTask.processDefinitionId, (err, sm) =>
        return next err if err

        sm.getNextStateName oldTask.state,data, (err,nextState) =>
          return next err if err
          totalTimeSpent =  0
          if oldTask.totalTimeSpent
            try
              totalTimeSpent = oldTask.totalTimeSpent
            catch e
              #nop
          
          if oldTask.checkedOutDate
            totalTimeSpent += new Date() - oldTask.checkedOutDate

          #if nextState is "end"

          data = 
            activeTaskUUID : null # to be deleted
            checkedOutByUserId: null
            checkedOutDate: null
            #state: is left alone
            stateCompleted: true
            nextState: nextState
            totalTimeSpent: totalTimeSpent

          @dbStore.tasks.patch req.params.taskId, data, {}, (err,item) =>
            return next err if err
            res.json item

  getBoard: (req,res,next) =>
    return res.json {},401 unless req.user

    processDefinitionId = "DUMMY" 

    @_stateMachineForProcessDefinitionId processDefinitionId, (err, sm) =>
      return next err if err

      board = 
        lanes: []

      for state,i in sm.getSwimlanes()
        board.lanes.push
          label: state.label
          name: state.name
          order: i

          activityDefinitions: [] # TBDeleted
          id: '' # TBDeleted
          totalTime : 0
          totalCost: 0
          executionTime : 0
          waitingTime: 0
          cards: []

      @dbStore.tasks.tasksForBoard processDefinitionId,{}, (err, pagedResult) =>
        return next err if err

        laneMap = {}
        laneMap[lane.name] = lane for lane in board.lanes

        for task in pagedResult.items || []
          lane = laneMap[task.state]

          if lane
            lane.cards.push 
                id : task._id
                desc : task.name || 'UNNAMED'
                #html : activity.description
                ready : task.stateCompleted
                state : lane.name
                processInstance : "" # REMOVE
                activityDefinitionUUID : "" # REMOVE
                totalTime :  0
                totalCost: 0
                executionTime : 0
                waitingTime: 0


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
          bonitaTaskUUID: task.activeTaskUUID 
          processInstanceUUID: task.processInstanceUUID
          taskId : task._id
          activeTask : task
        console.log "Task already active - returned"
        return

      processDefinitionId = "dummy"
      @_stateMachineForProcessDefinitionId processDefinitionId, (err, sm) =>
        return next err if err

        # HERE WE NEED TO TRANSFORM req.user.roles into allowed states.
        #states = ['qaChecks','shiftManagerApproval','productionManagerApproval']
        console.log "USER ROLES: #{req.user.roles}"
        states = sm.getStatesForRoles(req.user.roles)
        console.log "USER STATES: #{states}"

        @dbStore.tasks.getTaskForProcessDefinitionIdAndStates processDefinitionId,states,{}, (err,task) =>
          return next err if err

          return res.json {} unless task # No task found.

          data =
            checkedOutByUserId: req.user.id || req.user._id
            activeTaskUUID: "" 
            activeActivityName: ""
            state: task.nextState
            nextState : null
            stateCompleted: false
            checkedOutDate: new Date()

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
              bonitaTaskUUID: "" 
              processInstanceUUID: ""
              taskId : item._id
              activeTask : item

