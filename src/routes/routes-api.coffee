
_ = require 'underscore'

module.exports = class RoutesApi

  constructor:(settings) ->
    _.extend @,settings
    throw new Error("app parameter is required") unless @app
    throw new Error("passport parameter is required") unless @passport
    throw new Error("identityStore parameter is required") unless @identityStore

  setupLocals: () =>

  setupRoutes: () =>
    @app.get '/api/session', @getSession

  ###
  Retrieve the current session (e.g. the user that is currently logged in). 
  Returns a 404 if no session exists - e.g. no user is logged in.
  ###
  getSession: (req,res) =>
    return res.json {}, 404 unless req.user

    #console.log "CURRENT USER #{JSON.stringify(req.user.toRest(@baseUrl))}"
    res.json req.user.toRest(@baseUrl)
