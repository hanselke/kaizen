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
    @app.get '/app/board',@getBoard
    @app.get '/app/main',@getMain
    @app.get '/app/signin',@getSignin

  getApp: (req,res,next) =>
    res.render 'app/index.ejs',
          pretty: true

  getBoard: (req,res,next) =>
    res.render 'app/board.ejs',
          pretty: true

  getMain: (req,res,next) =>
    res.render 'app/main.ejs',
          pretty: true

  getSignin: (req,res,next) =>
    res.render 'app/signin.ejs',
          pretty: true
