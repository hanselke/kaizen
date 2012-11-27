
_ = require 'underscore'

module.exports = class RoutesApi

  constructor:(settings) ->
    _.extend @,settings
    throw new Error("app parameter is required") unless @app
    throw new Error("bonitaClient parameter is required") unless @bonitaClient
    @processName = "QA_Data_Entry"

  setupLocals: () =>

  setupRoutes: () =>
    @app.get '/api/session', @getSession

    # TODO: Ensure that we have a user here
    @app.get '/api/board', @getBoard

  ###
  Retrieve the current session (e.g. the user that is currently logged in). 
  Returns a 404 if no session exists - e.g. no user is logged in.
  ###
  getSession: (req,res) =>
    return res.json {}, 404 unless req.user

    #console.log "CURRENT USER #{JSON.stringify(req.user.toRest(@baseUrl))}"
    res.json req.user.toRest(@baseUrl)

  getBoard: (req,res) =>
    @bonitaClient.queryDefinition.getLastProcess @processName,req.user.username,null, (err,item) =>
      return res.json {}, 500 if err
      console.log "RESULT: #{JSON.stringify(item)}"

      res.json item
      