_ = require 'underscore'
async = require 'async'

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


  setupLocals: () =>
    #@app.use (req, res,next) =>
    #  next()
      
  setupRoutes: () =>
    @app.post '/admin/users/setup-demo', @setupDemoUsers


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
