_ = require 'underscore'
RoutesAppPathHelper = require './routes-app-path-helper'
protectResource = require '../site/protect-resource'

module.exports = class RoutesOther

  constructor:(settings) ->
    _.extend @,settings

    throw new Error("app parameter is required") unless @app

  setupLocals: () =>
    @app.locals.routesApps = @routesAppPathHelper = new RoutesAppPathHelper
    
      
  setupRoutes: () =>
    @app.get '/app',protectResource(), @getApp
    @app.get '/app/main',@getMain
    @app.get '/app/task',@getTask

  getApp: (req,res,next) =>
    res.render 'app/index.ejs',
          pretty: true


  getMain: (req,res,next) =>
    res.render 'app/main',
          pretty: true

  getTask: (req,res,next) =>
    res.render 'app/task',
          pretty: true
