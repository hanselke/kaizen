_ = require 'underscore'
async = require 'async'
winston = require 'winston'
errors = require 'some-errors'
fs = require 'fs'
xlsxToForm = require '../modules/xlsx-to-form'



module.exports = class RoutesApiAdminProcessDefinitions

  constructor:(settings) ->
    _.extend @,settings
    throw new Error("app parameter is required") unless @app

  setupLocals: () =>

  setupRoutes: () =>

    @app.get '/api/admin/process-definitions', @getAdminProcessDefinitions
    @app.post '/api/admin/process-definitions', @postAdminProcessDefinitions
    @app.delete '/api/admin/process-definitions/:processDefinitionId', @deleteAdminProcessDefinition
    
    #angular bug
    @app.patch '/api/admin/process-definitions/:processDefinitionId', @patchAdminProcessDefinition
    @app.put '/api/admin/process-definitions/:processDefinitionId', @patchAdminProcessDefinition
    
    @app.get '/api/admin/process-definitions/:processDefinitionId', @getAdminProcessDefinition
    @app.post '/api/admin/process-definitions/:processDefinitionId/excel', @uploadAdminProcessDefinitionExcel
    @app.get '/api/admin/process-definitions/:processDefinitionId/layout', @getAdminProcessDefinitionLayout
    @app.post '/api/admin/process-definitions/:processDefinitionId/layout', @uploadAdminProcessDefinitionLayout



  getAdminProcessDefinitions: (req,res,next) =>
    return res.json 401,{} unless req.user
    @dbStore.processDefinitions.all {actor:null, offset: 0, count: 200}, (err,result) =>
      return next err if err
      res.json result

 
  postAdminProcessDefinitions: (req,res,next) =>
    @dbStore.processDefinitions.create req.body,actorId : req.user._id, (err,item) =>
      res.json item

  deleteAdminProcessDefinition: (req,res,next) =>
    processDefinitionId = req.params.processDefinitionId
    @dbStore.processDefinitions.destroy processDefinitionId,null,true, (err,item) =>
      return next err if err
      res.json {}

  patchAdminProcessDefinition: (req,res,next) =>
    console.log JSON.stringify(req.body)
    processDefinitionId = req.params.processDefinitionId

    isValidStateMachine = true

    if req.body.stateMachine
      try
        json = JSON.parse(req.body.stateMachine)
      catch e
        isValidStateMachine = false

    if (req.body.taskNamePrefix || '').length > 8
      return res.json 422,{message: "The task name prefix must be 8 chars or less."}
    
    if !isValidStateMachine
      return res.json 422,{message: "State Machine is not valid. Please use jsonformatter.curiousconcept.com to validate"}

    @dbStore.processDefinitions.patch processDefinitionId,req.body,{}, (err,item) =>
      return next err if err
      res.json item


  getAdminProcessDefinition: (req,res,next) =>
    processDefinitionId = req.params.processDefinitionId
    @dbStore.processDefinitions.get processDefinitionId,null,true, (err,item) =>
      return next err if err

      hasSource = item.sourceXlsx && item.sourceXlsx.length >0
      hasLayout = item.layout && _.keys(item.layout).length > 0
      delete item.sourceXlsx
      delete item.layout

      item = item.toJSON()
      item.hasSource = hasSource
      item.hasLayout = hasLayout

      res.json item

  uploadAdminProcessDefinitionExcel: (req,res,next) =>
    processDefinitionId = req.params.processDefinitionId

    file = req.files.file
    return next new Error("No file present") unless file
    return next new Error("No processDefinitionId") unless processDefinitionId


    fs.readFile file.path, 'utf8', (err, content) =>
      return next err if err

      base64Content = new Buffer(content).toString('base64')

      @dbStore.processDefinitions.saveExcel processDefinitionId,base64Content,file.size,file.name,file.type, (err,item) =>
        return next err if err
        res.json {}

  getAdminProcessDefinitionLayout : (req,res,next) =>
    processDefinitionId = req.params.processDefinitionId
    @dbStore.processDefinitions.get processDefinitionId,null,true, (err,item) =>
      return next err if err
      res.setHeader 'Content-Disposition','Attachment'
      res.json item.layout

    #res.setHeader 'Content-Type', 'application/json'
    #res.send css



  uploadAdminProcessDefinitionLayout: (req,res,next) =>
    processDefinitionId = req.params.processDefinitionId

    file = req.files.file
    return next new Error("No file present") unless file
    return next new Error("No processDefinitionId") unless processDefinitionId

    fs.readFile file.path, 'utf8', (err, content) =>
      return next err if err

      parsedJson = null
      try
        parsedJson= JSON.parse content
      catch e
        return next new Error('Invalid JSON') unless parsedJson
      
      xlsxToForm.loadVbaOutput parsedJson, (err,converted) =>
        return next err if err

        @dbStore.processDefinitions.saveLayout processDefinitionId,converted, (err,item) =>
          return next err if err
          res.json {}

