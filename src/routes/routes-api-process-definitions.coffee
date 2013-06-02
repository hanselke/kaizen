_ = require 'underscore'
async = require 'async'
winston = require 'winston'
errors = require 'some-errors'
fs = require 'fs'
xlsxToForm = require '../modules/xlsx-to-form'
stateMachinePackage = require 'openb-app-state-machine'

mongoose = require "mongoose"
ObjectId = mongoose.Types.ObjectId


stateMachineForProcessDefinition = require './helpers/state-machine-for-process-definition'


module.exports = class RoutesApi


  constructor:(settings) ->
    _.extend @,settings
    throw new Error("app parameter is required") unless @app
    throw new Error("identityStore parameter is required") unless @identityStore

  setupLocals: () =>

  setupRoutes: () =>

    @app.get '/api/process-definitions/:processDefinitionId/validate', @validateProcessDefinition
    @app.get '/api/process-definitions/:processDefinitionId/form-css', @getProcessDefinitionCss
    @app.get '/api/process-definitions/:processDefinitionId/:taskId/form-html', @getProcessDefinitionHtml

  validateProcessDefinition: (req,res,next) =>
    processDefinitionId = req.params.processDefinitionId
    @dbStore.processDefinitions.get processDefinitionId,null,true, (err,item) =>
      return next err if err
      stateMachineForProcessDefinition item, (err, sm) =>
        return next err if err

        result = 
          processDefinition : 
            _id : item.id
            name : item.name

        res.json result

  ###
  http://localhost:8001/api/process-definitions/5101f5620cb4645c7800000b/form-css
  ###
  getProcessDefinitionCss: (req,res,next) =>
    processDefinitionId = req.params.processDefinitionId
    @dbStore.processDefinitions.get processDefinitionId,null,true, (err,item) =>
      return next err if err

      unless item && xlsxToForm.isValidLayout(item.layout)
        res.send "p.warning-box {margin-top:50px;background-color:red;color:white;}"
        return 


      xlsxToForm.createCssFromLayoutForm item.layout,(err,css) =>
        return done err if err

        res.setHeader 'Content-Type', 'text/css'
        res.send css



  ###
  http://localhost:8001/api/process-definitions/50d22f260b75ca1d9000000c/taskIdhere/form-html
  ###
  getProcessDefinitionHtml: (req,res,next) =>
    editAllStates = req.query.editAllStates


    processDefinitionId = req.params.processDefinitionId
    taskId = req.params.taskId
    @dbStore.processDefinitions.get processDefinitionId,null,true, (err,item) =>
      return next err if err

      unless item && xlsxToForm.isValidLayout(item.layout)
        res.send "<p class=\"warning\">Could not read Layout Definition for process #{item.name}</p>"
        return 

      stateMachineForProcessDefinition item, (err, sm) =>
        return next err if err

        @dbStore.tasks.get taskId, {}, (err,task) =>
          return next err if err

          currentTaskState = sm.getExcelFieldFromState( task.state) || 'undefined' 
          options =
            editAllStates: editAllStates
            isActiveInputCell : (cell) => 
              return false unless cell.text && cell.text.length > 0
              return false unless sm.existsAsExcelField( cell.text)
              true

            isActiveInputCellCurrent : (cell) => 
              return false unless cell.text && cell.text.length > 0
              return false unless cell.text is currentTaskState
              true


          xlsxToForm.createHtmlFromLayoutForm item.layout,options,(err,html) =>
            return done err if err

            html = "#{html}"
            res.send html

  ###
  _stateMachineForProcessDefinition: (processDefinition,cb) =>
    return cb new Error("No valid process defintions found.") unless processDefinition

    smData = null
    try
      smData = JSON.parse(processDefinition.stateMachine)
    catch e
      console.log "Could not parse statemachine for #{processDefinition.name}"
      console.log processDefinition.stateMachine
      return cb new Error("Could not parse JSON State Machine for Process Defintion #{processDefinition.name}")

    sm = stateMachinePackage.stateMachine()
    sm.loadFromObject smData

    cb null,sm
  ###

