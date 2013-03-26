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
    @app.get '/app/admin/change-password',@getChangePassword
    @app.get '/app/admin/users/add',@getAdminUsersAdd
    @app.get '/app/admin/roles',@getAdminRoles
    @app.get '/app/admin/roles/add',@getAdminRolesAdd
    @app.get '/app/admin/process-definitions',@getAdminProcessDefinitions
    @app.get '/app/admin/process-definitions/add',@getAdminProcessDefinitionsAdd
    @app.get '/app/admin/process-definitions/form',@getAdminProcessDefinitionsForm
    @app.get '/app/admin/process-definitions/layout',@getAdminProcessDefinitionsLayout
    @app.get '/app/admin/process-definitions/edit',@getAdminProcessDefinitionsEdit
    @app.get '/app/admin/tasks',@getAdminTasks
    @app.get '/app/help',@getHelp
    @app.get '/app/help/terms',@getHelpTerms
    @app.get '/app/help/setup',@getHelpSetup

  getHelp: (req,res,next) =>
    res.render 'app/help/index', #.ejs
          pretty: true
  getHelpSetup: (req,res,next) =>
    res.render 'app/help/setup', #.ejs
          pretty: true
  getHelpTerms: (req,res,next) =>
    res.render 'app/help/terms', #.ejs
          pretty: true


  getChangePassword: (req,res,next) =>
    res.render 'app/admin/users-changepassword',
          pretty: true

  getApp: (req,res,next) =>
    res.render 'app/index', #.ejs
          pretty: true


  getMain: (req,res,next) =>
    res.render 'app/main',
          pretty: true

  getTask: (req,res,next) =>
    res.render 'app/task',
          pretty: true

  getAdminTasks: (req,res,next) =>
    res.render 'app/admin/tasks',
          pretty: true

  getAdminUsers: (req,res,next) =>
    res.render 'app/admin/users',
          pretty: true

  getAdminUsersAdd: (req,res,next) =>
    res.render 'app/admin/users-add',
          pretty: true


  getAdminRoles: (req,res,next) =>
    res.render 'app/admin/roles',
          pretty: true

  getAdminRolesAdd: (req,res,next) =>
    res.render 'app/admin/roles-add',
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

  getAdminProcessDefinitionsLayout: (req,res,next) =>
    res.render 'app/admin/process-definitions-layout',
          pretty: true

  getAdminProcessDefinitionsEdit: (req,res,next) =>
    res.render 'app/admin/process-definition-edit',
          pretty: true
