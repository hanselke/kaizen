_ = require 'underscore-ext'
PageResult = require('simple-paginator').PageResult
PageResultInfinite = require('simple-paginator').PageResultInfinite
errors = require 'some-errors'

mongoose = require "mongoose"
ObjectId = mongoose.Types.ObjectId


#MAXCACHEDFOLLOWERS = 30
MAXFOLLOWERSPERBUCKET = 100
MAXCOUNTOBJECTS = 50

###
Provides methods to interact with processDefinitions.
###
module.exports = class ProcessDefinitionMethods
  CREATE_FIELDS = ['_id','name','description','createdBy','createableByRoles','stateMachine','taskNamePrefix','hasExcel','hasLayout','hasStateMachine']
  UPDATE_FIELDS = ['name','description','createdBy','sourceXlsx','sourceSize','sourceFilename','sourceType','createableByRoles','stateMachine','taskNamePrefix','hasExcel','hasLayout','hasStateMachine']

  ###
  Initializes a new instance of the @see ProcessDefinitionMethods class.
  @param {Object} models A collection of models that can be used.
  ###

  ###
  Initializes a new instance of the @see ProcessDefinitionMethods class.
  @param {Object} models A collection of models that can be used.
  ###
  constructor:(@models) ->

  all: (options = {},cb = ->) =>
    # TODO: EXCLUDE DELETED
    options.select or= '_id name description createableByRoles'
    options.offset or= 0
    options.count or=50

    @models.ProcessDefinition.count  {}, (err, totalCount) =>
      return cb err if err

      query = @models.ProcessDefinition.find({})
      query.select(options.select)
      query.setOptions { skip: options.offset, limit: options.count}
      query.exec (err, items) =>
        return cb err if err
        cb null, new PageResult(items || [], totalCount, options.offset, options.count)

  ###
  Retrieve a single processDefinition-item through it's id
  ###
  get: (processDefinitionId, actor, ignoreSecurity, cb = ->) =>
    @_getItem processDefinitionId, actor, ignoreSecurity, false, cb

  ###
  Retrieve a single processDefinition-item through it's id
  ###
  get2: (processDefinitionId, options = {}, cb = ->) =>
    processDefinitionId = new ObjectId(processDefinitionId.toString())
    query = @models.ProcessDefinition.findOne _id : processDefinitionId
    query = query.select(options.select) if options.select && options.select.length > 0
    query.exec cb

    
  getValidProcessDefinition: (options = {}, cb = ->) =>
    console.log "HERE"
    query = @models.ProcessDefinition.find() #.where("this.stateMachine && this.stateMachine.length > 10")
    query = query.select(options.select) if options.select && options.select.length > 0
    query.exec (err,result) =>
      return cb err if err
      for x in result
        if x.stateMachine && x.stateMachine.length > 10
          return cb null, x
      return cb new Error('Not suitable process definition found')


  firstProcessDefinition: ( options = {}, cb = ->) =>
    query = @models.ProcessDefinition.findOne()
    query = query.select(options.select) if options.select && options.select.length > 0
    query.exec cb



  createOrPut :(objs = {}, actor, cb = ->) =>
    return cb new errors.UnprocessableEntity("_id") unless objs._id
    @_getItem objs._id, null, true, false, (err, item) =>
      return cb err if err
      if item
        @put objs._id,objs,actor,true,cb
      else
        @create objs,actor,cb


  ###
  Create a new processDefinition
  ###
  create:(objs = {}, actor, cb = ->) =>
    data = {}
    data.createdBy = actor

    objs.createableByRoles = objs.createableByRoles.split(',') if objs.createableByRoles && _.isString(objs.createableByRoles)

    _.extendFiltered data, CREATE_FIELDS, objs
    return cb new errors.UnprocessableEntity("createdBy") unless data.createdBy && data.createdBy.actorId

    model = new @models.ProcessDefinition(data)
    model.save (err) =>
      return cb err if err
      cb(null, model,true)

  delete: (processDefinitionId, actor, ignoreSecurity, cb = ->) =>
    @_getItem processDefinitionId, actor, ignoreSecurity, true, (err, item) =>
      return cb err if err
      return cb(null) unless item
      return cb null if item.isDeleted

      item.isDeleted = true
      item.deletedAt = new Date()
      item.save (err) =>
        return cb err if err
        cb null

  destroy: (processDefinitionId, actor, ignoreSecurity, cb = ->) =>
    @_getItem processDefinitionId, actor, ignoreSecurity, true, (err, item) =>
      return cb err if err
      return cb(null) unless item

      item.remove (err) =>
        return cb err if err
        cb null

  undelete: (processDefinitionId, actor, ignoreSecurity, cb = ->) =>
    @_getItem processDefinitionId, actor, ignoreSecurity, true, (err, item) =>
      return cb err if err
      return cb new errors.NotFound("/processDefinitions/#{processDefinitionId}") unless item

      return cb null, item unless item.isDeleted

      item.isDeleted = false
      item.deletedAt = null
      item.save (err) =>
        return cb err if err
        cb null, item

  patch: (processDefinitionId, obj = {}, options = {}, cb = ->) =>
    @_getItem processDefinitionId, options.actor, options.ignoreSecurity, true, (err, item) =>
      return cb err if err
      return cb new errors.NotFound("/processDefinitions/#{processDefinitionId}") unless item

      obj.createableByRoles = obj.createableByRoles.split(',') if obj.createableByRoles && _.isString(obj.createableByRoles)
      _.extendFiltered item, UPDATE_FIELDS, obj
      item.save (err) =>
        return cb err if err
        cb null, item

  put: (processDefinitionId, obj = {}, actor, ignoreSecurity, cb = ->) =>
    @_getItem processDefinitionId, actor, ignoreSecurity, true, (err, item) =>
      return cb err if err
      return cb new errors.NotFound("/processDefinitions/#{processDefinitionId}") unless item

      obj.createableByRoles = obj.createableByRoles.split(',') if obj.createableByRoles && _.isString(obj.createableByRoles)

      item[field] = null for field in UPDATE_FIELDS
      _.extendFiltered item, UPDATE_FIELDS, obj

      item.save (err) =>
        return cb err if err
        cb null, item

  _getItem: (processDefinitionId, actor, ignoreSecurity, forWrite, cb) =>
    processDefinitionId = new ObjectId(processDefinitionId.toString())
    @models.ProcessDefinition.findOne _id : processDefinitionId, cb

  saveLayout: (processDefinitionId,layout,cb) =>

    @_getItem processDefinitionId, null, true, true, (err, item) =>
      return cb err if err
      return cb new errors.NotFound("/processDefinitions/#{processDefinitionId}") unless item

      item.layout = layout
      item.markModified 'layout'
      item.hasLayout = true
      item.save (err) =>
        return cb err if err
        cb null, item


  saveExcel: (processDefinitionId,base64Content,fileSize,fileName,fileType,cb) =>

    @_getItem processDefinitionId, null, true, true, (err, item) =>
      return cb err if err
      return cb new errors.NotFound("/processDefinitions/#{processDefinitionId}") unless item

      item.sourceXlsx = base64Content
      item.sourceSize = fileSize
      item.sourceFilename = fileName
      item.sourceType = fileType
      item.hasExcel = true

      item.save (err) =>
        return cb err if err
        cb null, item
