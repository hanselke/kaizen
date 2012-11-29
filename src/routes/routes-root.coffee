_ = require 'underscore'
RoutesRootPathHelper = require './routes-root-path-helper'
protectResource = require '../site/protect-resource'

module.exports = class RoutesOther

  constructor:(settings) ->
    _.extend @,settings

    throw new Error("app parameter is required") unless @app

  setupLocals: () =>
    @app.locals.routesRoot =  @routesRootPathHelper = new RoutesRootPathHelper
      
  setupRoutes: () =>
    @app.get '/', @home
    @app.get '/status', @status

  home: (req, res, next) =>
    res.redirect "/app"

  status: (req, res, next) =>
    res.json
      running: true
      uptime: process.uptime()
      memoryUsage: process.memoryUsage()
      versions: process.versions
      pid: process.pid

