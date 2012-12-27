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
    @app.get '/app/admin/users',@getAdminUsers
    @app.get '/app/admin/users/add',@getAdminUsersAdd
    @app.get '/app/admin/process-definitions',@getAdminProcessDefinitions
    @app.get '/app/admin/process-definitions/add',@getAdminProcessDefinitionsAdd
    @app.get '/app/admin/process-definitions/form',@getAdminProcessDefinitionsForm

  getApp: (req,res,next) =>
    res.render 'app/index', #.ejs
          pretty: true


  getMain: (req,res,next) =>
    res.render 'app/main',
          pretty: true

  getTask: (req,res,next) =>
    res.render 'app/task',
          pretty: true

  getAdminUsers: (req,res,next) =>
    res.render 'app/admin/users',
          pretty: true

  getAdminUsersAdd: (req,res,next) =>
    res.render 'app/admin/users-add',
          pretty: true


  getAdminProcessDefinitions: (req,res,next) =>
    res.render 'app/admin/process-definitions',
          pretty: true

  getAdminProcessDefinitionsAdd: (req,res,next) =>
    res.render 'app/admin/process-definitions-add',
          pretty: true

  getAdminProcessDefinitionsForm: (req,res,next) =>
    res.render 'app/admin/process-definitions-form',
          pretty: true
