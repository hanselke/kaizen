_ = require 'underscore'
async = require 'async'
winston = require 'winston'
errors = require 'some-errors'
fs = require 'fs'
xlsxToForm = require '../modules/xlsx-to-form'
stateMachinePackage = require '../modules/state-machine'



module.exports = class RoutesApiBoards

  constructor:(settings) ->
    _.extend @,settings
    throw new Error("app parameter is required") unless @app

  setupLocals: () =>

  setupRoutes: () =>

    @app.get '/api/admin/boards', @getAdminBoards
    @app.post '/api/admin/boards', @postAdminBoards
    @app.delete '/api/admin/boards/:boardId', @deleteAdminBoard
    
    #angular bug
    @app.patch '/api/admin/boards/:boardId', @patchAdminBoard
    @app.put '/api/admin/boards/:boardId', @patchAdminBoard
    
    @app.get '/api/admin/boards/:boardId', @getAdminBoard



  getAdminBoards: (req,res,next) =>
    return res.json 401,{} unless req.user
    @dbStore.boards.all {actor:null, offset: 0, count: 200}, (err,result) =>
      return next err if err
      res.json result

 
  postAdminBoards: (req,res,next) =>
    @dbStore.boards.create req.body,actorId : req.user._id, (err,item) =>
      res.json item

  deleteAdminBoard: (req,res,next) =>
    boardId = req.params.boardId
    @dbStore.boards.destroy boardId, {}, (err,item) =>
      return next err if err
      res.json {}

  patchAdminBoard: (req,res,next) =>
    boardId = req.params.boardId

    isValidStateMachine = true

    ###
    if req.body.stateMachine
      try
        json = JSON.parse(req.body.stateMachine)
      catch e
        isValidStateMachine = false

    if (req.body.taskNamePrefix || '').length > 8
      return res.json 422,{message: "The task name prefix must be 8 chars or less."}
    
    if !isValidStateMachine
      return res.json 422,{message: "State Machine is not valid. Please use jsonformatter.curiousconcept.com to validate"}
    ###
    @dbStore.boards.patch boardId,req.body,{}, (err,item) =>
      return next err if err
      res.json item


  getAdminBoard: (req,res,next) =>
    boardId = req.params.boardId
    @dbStore.boards.get boardId, {}, (err,item) =>
      return next err if err
      res.json item

