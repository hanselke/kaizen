_ = require 'underscore'

module.exports = class RoutesLegacy

  constructor:(settings) ->
    _.extend @,settings

    throw new Error("app parameter is required") unless @app

  setupLocals: () =>
    #@app.use (req, res,next) =>
    #  next()
      
  setupRoutes: () =>

    ###
    @app.post '/sales', andLoggedIn, backend.create_task
    @app.get '/tasks/:idx?', backend.tasks
    @app.get '/quotes', backend.quotes
    @app.post '/users', backend.create_user
    @app.post '/login', app.session_mw, backend.login
    @app.post '/logout', backend.logout
    @app.get '/current_user', backend.current_user
    @app.post '/faxes', backend.create_fax 
    @app.get '/board', backend.board 
    @app.get '/bods/:bodid', backend.show_bod 
    @app.get '/ourselves', backend.ourselves
    ###
