_ = require 'underscore'
async = require 'async'
winston = require 'winston'
errors = require 'some-errors'

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
    @app.get '/api/admin/users', @getAdminUsers
    @app.post '/api/admin/users', @postAdminUsers
    @app.delete '/api/admin/users/:userId', @deleteAdminUser
    @app.post '/api/admin/users/synctobonita',@syncToBonita
    @app.post '/api/admin/users/syncfrombonita',@syncFromBonita

    # This is a hack
    @app.post '/api/admin/users/:userId/roles/:role', @addRole
    @app.delete '/api/admin/users/:userId/roles/:role', @deleteRole

  ###
  Retrieve the current session (e.g. the user that is currently logged in). 
  Returns a 404 if no session exists - e.g. no user is logged in.
  ###
  getSession: (req,res) =>
    return res.json {}, 404 unless req.user

    #console.log "CURRENT USER #{JSON.stringify(req.user.toRest(@baseUrl))}"
    res.json req.user.toRest(@baseUrl)

  getBoard: (req,res,next) =>
    return res.json {},401 unless req.user
    @bonitaClient.queryDefinition.getProcesses req.user.username,null, (err,processes) =>
      return next err if err
      #console.log "GETPROCESSES=========="
      #console.log "#{JSON.stringify(processes)}"
      #console.log "GETPROCESSES##########"

      ###
      @bonitaClient.queryDefinition.getLastProcess @servicesBonita.processName,req.user.username,null, (err,process) =>
        return next err if err
        #console.log "GETLASTPROCESS: #{JSON.stringify(process)}"
        processUUID = process?.uuid?.value
      ###

      processDefinition = _.first processes.ProcessDefinition

      processUUID = processDefinition?.uuid?.value

      return res.json {message: "processUUID not available from getLastProcess."},500 unless processUUID

      @bonitaClient.queryRuntime.getProcessInstances processUUID,req.user.username,null, (err,processInstances) =>
        return next err if err
        return res.json {message: "processInstances not available from getProcessInstances."},500 unless processInstances
        board = @bonitaTransformer.toBoard processes,processInstances
        console.log "RESULT: #{JSON.stringify(board)}"
        res.json board


  ###
  Sample:
    {"processUUID":{"value":"QA_Data_Entry--1.2"},"instanceUUID":{"value":"QA_Data_Entry--1.2--9"},"rootInstanceUUID":{"value":"QA_Data_Entry--1.2--9"},"uuid":{"value":"QA_Data_Entry--1.2--9--Enter_Floor_Data--itb7637faf-37c4-4cfb-9d10-4306be713a16--mainActivityInstance--noLoop"},"iterationId":"itb7637faf-37c4-4cfb-9d10-4306be713a16","activityInstanceId":"mainActivityInstance","loopId":"noLoop","state":"READY","userId":"admin","lastUpdate":"1353306603343","label":"Enter Floor Data","description":{},"name":"Enter_Floor_Data","startedDate":"0","endedDate":"0","readyDate":"1353306603263","activityDefinitionUUID":{"value":"QA_Data_Entry--1.2--Enter_Floor_Data"},"expectedEndDate":"0","priority":"0","type":"Human","human":"true","stateUpdates":{"StateUpdate":{"dbid":"0","date":"1353306603263","state":"READY","updateUserId":"SYSTEM","initialState":"READY"}},"clientVariables":{},"variableUpdates":{},"assignUpdates":{"AssignUpdate":{"dbid":"0","date":"1353306603345","state":"READY","updateUserId":"SYSTEM","userId":"admin"}},"candidates":{}}}
  ###
  getTasks: (req,res,next) =>
    console.log "RE: #{JSON.stringify(req.query)} AND #{JSON.stringify(req.params)}"
    return res.json {},401 unless req.user
    procInstUUID = req.params.procInstUUID || req.query.procInstUUID

    return res.json {},422 unless procInstUUID

    @bonitaClient.queryRuntime.getTaskList procInstUUID, "READY",req.user.username,null, (err,taskList) =>
      return next err if err

      console.log "RAW: #{JSON.stringify(taskList)}"
      result = @bonitaTransformer.toNextAction taskList,@servicesBonita.baseUrl
      
      console.log "PRETRANS #{JSON.stringify(result)}"
      

      if result.taskUUID
        @bonitaClient.runtime.assignTask result.taskUUID,req.user.username,req.user.username,{}, (err) =>
          # Deal with task
          console.log "TRANSFORMED: #{JSON.stringify(tasks)}"

          res.json result
      else
        res.json result


  getAdminUsers: (req,res,next) =>
    return res.json {}, 401 unless req.user
    @bonitaClient.identity.getAllRoles  "admin",{}, (err,roles) =>
      return next err if err
      @identityStore.users.all 0,100, (err,result) =>
        return next err if err
        result.roles = _.map roles.Role, (x) -> {name : x.name,label : x.label}
        console.log JSON.stringify(result)
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
    console.log "DELETE USER #{userId}"
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
      #console.log JSON.stringify(users)
      
      createOrUpdate = (user,cb) =>
        console.log user.username
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
        res.json {}

  deleteRole: (req,res,next) =>
    userId = req.params.userId
    role = req.params.role

    console.log "DELETE ROLE #{userId} #{role}"

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

    console.log "ADD ROLE #{userId} #{role}"

    @identityStore.users.addRoles userId,[role], (err,r,item) =>
      return next err if err

      if item      
        @bonitaClient.identity.addRoleToUser item.username,role,"admin",null, (err,u) =>
          #return next err if err
          res.json {}
      else
        res.json {}
