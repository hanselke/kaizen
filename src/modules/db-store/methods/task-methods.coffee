_ = require 'underscore-ext'
PageResult = require('simple-paginator').PageResult
PageResultInfinite = require('simple-paginator').PageResultInfinite
errors = require 'some-errors'

mongoose = require "mongoose"
ObjectId = mongoose.Types.ObjectId


module.exports = class TaskMethods
  CREATE_FIELDS = ['_id','processDefinitionId','checkedOutByUserId','createdBy','state','activeTaskUUID','processInstanceUUID']
  UPDATE_FIELDS = ['processDefinitionId','checkedOutByUserId','state','activeTaskUUID']

  constructor:(@models) ->


  ###
  Create a new processDefinition
  ###
  create:(objs = {}, actor, cb = ->) =>
    data = {}
    data.createdBy = actor unless data.createdBy

    _.extendFiltered data, CREATE_FIELDS, objs
    return cb new errors.UnprocessableEntity("createdBy") unless data.createdBy && data.createdBy.actorId

    model = new @models.Task(data)
    model.save (err) =>
      return cb err if err
      cb(null, model,true)

  ###
  Retrieves the currently active task, if any, for a user.
  ###
  getActiveTask: (userId,options = {}, cb) =>
    userId = userId.toString()
    @models.Task.findOne {checkedOutByUserId : userId,state: 'active'}, (err,item) =>
      return cb err if err
      cb null, item

  ###
  Retrieve a single processDefinition-item through it's id
  ###
  get: (taskId,options = {}, cb = ->) =>
    @models.Task.findOne _id : taskId, (err,item) =>
      return cb err if err
      cb null, item

  patch: (taskId, obj = {}, options={}, cb = ->) =>
    @models.Task.findOne _id : taskId, (err,item) =>
      return cb err if err
      return cb new errors.NotFound("/tasks/#{taskId}") unless item

      _.extendFiltered item, UPDATE_FIELDS, obj
      item.save (err) =>
        return cb err if err
        cb null, item


  patchByProcessInstanceUUID: (processInstanceUUID, obj = {}, options={}, cb = ->) =>
    @models.Task.findOne processInstanceUUID : processInstanceUUID, (err,item) =>
      return cb err if err
      return cb new errors.NotFound("/tasks/byProcessInstance#{processInstanceUUID}") unless item

      _.extendFiltered item, UPDATE_FIELDS, obj
      item.save (err) =>
        return cb err if err
        cb null, item


