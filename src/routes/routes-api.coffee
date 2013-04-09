_ = require 'underscore'
async = require 'async'
winston = require 'winston'
errors = require 'some-errors'
fs = require 'fs'
xlsxToForm = require '../modules/xlsx-to-form'
stateMachinePackage = require '../modules/state-machine'
stateMachineForProcessDefinition = require './helpers/state-machine-for-process-definition'

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

