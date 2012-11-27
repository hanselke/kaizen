
_ = require 'underscore'

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
    @bonitaClient.queryDefinition.getLastProcess @servicesBonita.processName,req.user.username,null, (err,process) =>
      return next err if err
      #console.log "RESULT: #{JSON.stringify(process)}"

      processUUID = process?.uuid?.value
      return res.json {message: "processUUID not available from getLastProcess."},500 unless processUUID

      @bonitaClient.queryRuntime.getProcessInstances processUUID,req.user.username,null, (err,processInstances) =>
        return next err if err
        return res.json {message: "processInstances not available from getProcessInstances."},500 unless processInstances
        board = @bonitaTransformer.toBoard process,processInstances
        console.log "RESULT: #{JSON.stringify(board)}"
        res.json board

