_ = require 'underscore-ext'
PageResult = require('simple-paginator').PageResult
PageResultInfinite = require('simple-paginator').PageResultInfinite
errors = require 'some-errors'

mongoose = require "mongoose"
ObjectId = mongoose.Types.ObjectId


module.exports = class TaskMethods
  CREATE_FIELDS = ['_id','processDefinitionId','checkedOutByUserId','createdBy','state','activeTaskUUID','processInstanceUUID','checkedOutDate','totalAbsoluteTimeSpent','totalTimeSpent','activeActivityName']
  UPDATE_FIELDS = ['processDefinitionId','checkedOutByUserId','state','activeTaskUUID','checkedOutDate','totalAbsoluteTimeSpent','totalTimeSpent','activeActivityName']

  constructor:(@models) ->


  all: (options = {},cb = ->) =>
    # TODO: EXCLUDE DELETED

    @models.Task.count  {}, (err, totalCount) =>
      return cb err if err

      query = @models.Task.find({})
      query.sort('-createdAt')
      query.select(options.select || '_id processDefinitionId processInstanceUUID state createdAt activeTaskUUID checkedOutByUserId')
      query.setOptions { skip: options.offset, limit: options.count}
      query.exec (err, items) =>
        return cb err if err
        cb null, new PageResult(items || [], totalCount, options.offset, options.count)


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
    # ,state: 'active'
    @models.Task.findOne {checkedOutByUserId : userId}, (err,item) =>
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
      if !item 
        @models.ProcessDefinition.find({}).select('_id bonitaProcessName').exec (err,items) =>
          processDefinitionId = _.first(items)._id
          for xx in items
            if processInstanceUUID.substr(0,xx.bonitaProcessName.length) is xx.bonitaProcessName
              processDefinitionId = xx._id

          item = new @models.Task
              processInstanceUUID : processInstanceUUID
              createdBy : options.actor
              processDefinitionId : processDefinitionId

          _.extendFiltered item, UPDATE_FIELDS, obj
          item.save (err) =>
            return cb err if err
            cb null, item
      else
        _.extendFiltered item, UPDATE_FIELDS, obj
        item.save (err) =>
          return cb err if err
          cb null, item
