_ = require 'underscore'
async = require 'async'
winston = require 'winston'
errors = require 'some-errors'
fs = require 'fs'
XLSX = require 'xlsx'
xlsxToForm = require '../modules/xlsx-to-form'


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
    @app.get '/api/tasks', @getTasks
    @app.post '/api/tasks', @createTask
    @app.post '/api/tasks/:taskId/complete', @completeTask
    @app.post '/api/tasks/:taskId/data', @saveTaskData
    @app.get '/api/tasks/:taskId/data', @getTaskData

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
    @app.get '/api/process-definitions/:processDefinitionId/form-css', @getProcessDefintionCss
    @app.get '/api/process-definitions/:processDefinitionId/form-html', @getProcessDefintionHtml


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

  getBoard: (req,res,next) =>
    return res.json {},401 unless req.user

    processName = @servicesBonita.processName
    #@bonitaClient.queryDefinition.getProcesses req.user.username,null, (err,processes) =>

    @bonitaClient.queryDefinition.getLastProcess processName, req.user.username,null, (err,process) => 
      console.log "Processes ------"
      console.log JSON.stringify(process)
      console.log "Processes ------"
      return next err if err

      
      #processDefinition = _.find( processes.ProcessDefinition, (x) -> x.name is processName && x.state is "ENABLED")

      #processUUID = processDefinition?.uuid?.value

      processDefinition = process
      processUUID = process.uuid?.value

      return res.json {message: "processUUID not available from getProcesses."},500 unless processUUID

      #console.log "PICKED ProcessInstance: #{processUUID}"

      @bonitaClient.queryRuntime.getProcessInstances processUUID,req.user.username,null, (err,processInstances) =>
        console.log "*************"
        console.log "#{JSON.stringify(processInstances)}"
        console.log "*************"
        return next err if err
        return res.json {message: "processInstances not available from getProcessInstances."},500 unless processInstances
        board = @bonitaTransformer.toBoard processDefinition,processInstances
        console.log "RESULT: #{JSON.stringify(board)}"
        res.json board


  ###
  Purpose is to retrieve the next eligible task for a user.
  Scenario:
    1. curl -X POST -d 'options=user:jack' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: application/xml' -H 'Authorization: Basic cmVzdHVzZXI6cmVzdGJwbQ=='  http://ec2-54-251-77-171.ap-southeast-1.compute.amazonaws.com:8080/bonita-server-rest/API/queryRuntimeAPI/getOneTask/READY
    2. curl -X POST -d 'options=user:jack' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: application/xml' -H 'Authorization: Basic cmVzdHVzZXI6cmVzdGJwbQ=='  http://ec2-54-251-77-171.ap-southeast-1.compute.amazonaws.com:8080/bonita-server-rest/API/runtimeAPI/executeTask/QA_Data_Entry--1.51--7--Assign_enter_floor_data--it079eb8be-05f5-473e-805f-7e5ad655ae26--mainActivityInstance--noLoop/true
    3. curl -X POST -d 'options=user:jack' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: application/xml' -H 'Authorization: Basic cmVzdHVzZXI6cmVzdGJwbQ=='  http://ec2-54-251-77-171.ap-southeast-1.compute.amazonaws.com:8080/bonita-server-rest/API/queryRuntimeAPI/getTask/QA_Data_Entry--1.51--7--Assign_enter_floor_data--it079eb8be-05f5-473e-805f-7e5ad655ae26--mainActivityInstance--noLoop
    4. curl -X POST -d 'options=user:jack' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: application/xml' -H 'Authorization: Basic cmVzdHVzZXI6cmVzdGJwbQ=='  http://ec2-54-251-77-171.ap-southeast-1.compute.amazonaws.com:8080/bonita-server-rest/API/queryRuntimeAPI/getOneTaskByProcessInstanceUUIDAndActivityState/QA_Data_Entry--1.51--7/READY
    5. curl -X POST -d 'options=user:jack' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: application/xml' -H 'Authorization: Basic cmVzdHVzZXI6cmVzdGJwbQ=='  http://ec2-54-251-77-171.ap-southeast-1.compute.amazonaws.com:8080/bonita-server-rest/API/runtimeAPI/startTask/QA_Data_Entry--1.51--7--_1_Enter_Floor_Data--it079eb8be-05f5-473e-805f-7e5ad655ae26--mainActivityInstance--noLoop/true

  ###

  getTasks: (req,res,next) =>
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


  completeTask: (req,res,next) =>
    return res.json 401,{} unless req.user

    @dbStore.tasks.patch req.params.taskId, {state: 'complete'}, {}, (err,item) =>
      res.json item


  createTask: (req,res,next) =>
    return res.json 401,{} unless req.user
    return res.json 422,{} unless req.body.processDefinitionId

    @bonitaClient.queryDefinition.getLastProcess @servicesBonita.processName, "admin",{},(err,process) =>
      return next err if err

      processUUID = process?.uuid?.value
      return res.send {} unless processUUID

      @bonitaClient.runtime.instantiateProcess processUUID, req.user.username,{},(err,newProcess) =>
        return next err if err

        processInstanceUUID = newProcess?.value

        payload =
          processInstanceUUID: processInstanceUUID
          processDefinitionId: req.body.processDefinitionId
          checkedOutByUserId: req.user._id

        @dbStore.tasks.create payload,actorId : req.user._id, (err,item) =>
          item.id = item._id
          res.json item



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

      delete item.sourceXlsx
      res.json item

  uploadAdminProcessDefinition: (req,res,next) =>
    processDefinitionId = req.params.processDefinitionId

    file = req.files.file
    return next new Error("No file present") unless file

    xlsx = XLSX.readFile(file.path)
    console.log "SHEETNAME: #{xlsx.SheetNames[0]}"

    console.log JSON.stringify(xlsx.Sheets[xlsx.SheetNames[0]])
    ###
    for z of xlsx.SheetNames[0]
      continue  if z[0] is "!"
      console.log y + "!" + z + "=" + JSON.stringify(zip.Sheets[y][z].v)
    ###

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

  ###
  http://localhost:8001/api/process-definitions/50d22f260b75ca1d9000000c/form-css
  ###
  getProcessDefintionCss: (req,res,next) =>
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
  http://localhost:8001/api/process-definitions/50d22f260b75ca1d9000000c/form-html
  ###
  getProcessDefintionHtml: (req,res,next) =>
    processDefinitionId = req.params.processDefinitionId
    @dbStore.processDefinitions.get processDefinitionId,null,true, (err,item) =>
      return next err if err

      layout1Path = "#{__dirname}/../../test/fixtures/form1-layout-raw.json"

      xlsxToForm.loadAndConvertVba layout1Path, (err,converted) =>
        return done err if err
        xlsxToForm.createHtmlFromLayoutForm converted,(err,html) =>
          return done err if err

#<link rel="stylesheet" type="text/css" href="https://mailfoogae.appspot.com/build/combined-5.0.css">

          html = "<html><head><link rel=\"stylesheet\" type=\"text/css\" href=\"http://localhost:8001/api/process-definitions/50d22f260b75ca1d9000000c/form-css\" /></head><body> #{html}</body></html>"
          res.send html

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

      result = []
      for key,v of item.data
        rc = key.split('-')
        result.push 
          r : rc[0]
          c : rc[1]
          v : v

      res.json result


