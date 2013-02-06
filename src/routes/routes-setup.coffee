
_ = require 'underscore'

module.exports = class RoutesSetup

  constructor:(settings) ->
    _.extend @,settings
    throw new Error("app parameter is required") unless @app
    throw new Error("passport parameter is required") unless @passport
    throw new Error("identityStore parameter is required") unless @identityStore

  setupLocals: () =>
    #

  setupRoutes: () =>
    @app.post '/setup',  @setup


  ###
  curl -X POST http://localhost:8001/setup
  ###
  setup: (req, res,next) =>
    data = 
      roles: ['admin']
      username: 'admin'
      password: 'bpm'
      primaryEmail: 'bpm@admin.com'

    @identityStore.users.create data, (err,user) =>
          return next err if err
          res.json {message: "success"}

