_ = require 'underscore'
async = require 'async'
winston = require 'winston'
errors = require 'some-errors'

sampleUsers =
  "andras@openbusiness.com.sg":
    company_name: "X"
    password: "aaa"
    roles: ["backoffice", "sales", "purchasing"]
    name: "Andras"
    username: "psmith"
    primaryEmail: "andras@openbusiness.com.sg"

  "noroles@openbusiness.com.sg":
    company_name: "GUAN-HUAT"
    password: "xxx"
    username: 'noroles'
    primaryEmail: "noroles@openbusiness.com.sg"

  "sales@openbusiness.com.sg":
    company_name: "GUAN-HUAT"
    password: "sales"
    roles: ["sales"]
    username: "sales"
    primaryEmail: "sales@openbusiness.com.sg"

  "hanselke@openbusiness.com.sg":
    company_name: "openbiz"
    password: "demo"
    roles: ["backoffice", "sales", "purchasing"]
    name: "Hansel Ke"
    username: "hansel"
    primaryEmail: "hanselke@openbusiness.com.sg"

  "onetom@openbusiness.com.sg":
    company_name: "Open Business"
    password: "xxx"
    roles: ["backoffice", "sales", "purchasing"]
    name: "Tom"
    username: "onetom"
    primaryEmail: "onetom@openbusiness.com.sg"


module.exports = class RoutesAdminUsers
  constructor:(settings) ->
    _.extend @,settings
    throw new Error("app parameter is required") unless @app
    throw new Error("identityStore parameter is required") unless @identityStore
    throw new Error("bonitaClient parameter is required") unless @bonitaClient


  setupLocals: () =>
    #@app.use (req, res,next) =>
    #  next()
      
  setupRoutes: () =>
    @app.post '/admin/users/setup-demo', @setupDemoUsers
    @app.post '/admin/users/sync-to-bonita', @syncToBonita
    @app.post '/admin/users/add-user-sync', @addUserSync
    @app.post '/admin/users/:username/roles', @addRolesToUser


  ###
  Temporary helper to setup demo users. To do this run this once:
  curl -X POST -d '{"roles" :["admin","user","test"]}' -H 'Content-Type: application/json' -H 'Accept: application/json' http://127.0.0.1:8001/admin/users/mw1/roles
  ###
  addRolesToUser: (req,res,next) =>
    username = req.params.username
    return next new errors.UnprocessableEntity("roles") unless req.body.roles && req.body.roles.length > 0
    @identityStore.users.getByName username,(err,user) =>
      return next err if err
      return next new errors.NotFound("/users/#{username}") unless user._id
      @identityStore.users.addRoles user._id,req.body.roles, (err) =>
        return next err if err

        addRole = (role,cb) =>
          winston.info "Adding role #{role} to #{username}"
          @bonitaClient.identity.addRoleToUser username, role,"admin",{},(err) =>
            winston.error "Failed adding role #{role} to #{username} - Check if role exists" if err
            cb null

        async.forEach req.body.roles ,addRole, (err) =>
          # Here we will never have an error, as we are passing null in the little ones.
          res.json {}

  ###
  Temporary helper to setup demo users. To do this run this once:
  curl -X POST -d '{}' -H 'Content-Type: application/json' -H 'Accept: application/json' http://127.0.0.1:8001/admin/users/setup-demo
  ###
  setupDemoUsers: (req, res, next) =>

    createUser = (user,cb) =>
      @identityStore.users.create user, (err) =>
        # We ignore err here.
        cb null # We ignore error here. Cheap way to handle multiple invocations.

    async.forEach _.values(sampleUsers),createUser, (err) =>
      # We ignore err here.
      res.json {}

  ###
  Add a user to passport and bonita
  curl -X POST -d '{"username" : "mw8", "password": "testabc", "primaryEmail": "mw5@test.com","roles" : ["admin","sales","purchasing"]}' -H 'Content-Type: application/json' -H 'Accept: application/json' http://127.0.0.1:8001/admin/users/add-user-sync
  ###
  addUserSync: (req,res,next) =>
    return next new errors.UnprocessableEntity("username") unless req.body.username
    return next new errors.UnprocessableEntity("password") unless req.body.password
    req.roles = [] unless req.roles

    @identityStore.users.create req.body, (err,user) =>
      return next err if err
      @bonitaClient.identity.addUser req.body.username,req.body.password,"admin",null, (err,u) =>
        return next err if err
        res.json user


  ###
  Sync users into bonita
  curl -X POST -d '{}' -H 'Content-Type: application/json' -H 'Accept: application/json' http://127.0.0.1:8001/admin/users/sync-to-bonita
  ###
  syncToBonita: (req,res,next) =>
    @identityStore.users.all 0,100, (err,result) =>
      winston.error JSON.stringify(err) if err
      return next err if err
      {items} = result

      createUserInBonita = (user,cb) =>
        @bonitaClient.identity.addUser user.username,"test1234","admin",null, (err,u) =>
          cb null

      async.forEach items || [], createUserInBonita, (err) =>
        res.json {}
