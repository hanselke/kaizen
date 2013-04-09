_ = require 'underscore-ext'
PageResult = require('simple-paginator').PageResult
PageResultInfinite = require('simple-paginator').PageResultInfinite
errors = require 'some-errors'

mongoose = require "mongoose"
ObjectId = mongoose.Types.ObjectId


module.exports = class TaskMethods
  CREATE_FIELDS = ['_id','processDefinitionId','checkedOutByUserId','createdBy','state','checkedOutDate','totalWaitingTime','totalActiveTime','activeActivityName','stateCompleted','nextState','name','taskEnded','checkedInDate','message','timePerState','previousState','onHold']
  UPDATE_FIELDS = ['processDefinitionId','checkedOutByUserId','state','checkedOutDate','totalWaitingTime','totalActiveTime','activeActivityName','stateCompleted','nextState','name','taskEnded','checkedInDate','message','timePerState','previousState','onHold']

  constructor:(@models) ->

  # Current state has been completed
  # Not checked out by any user.
  # nextState in list of states
  getTaskForStates: (states = [],options = {},cb = ->) =>
    query = @models.Task.findOne({stateCompleted : true, checkedOutByUserId : null, taskEnded : false})
    query.sort('-createdAt')
    query.where('nextState').in(states)
    query.exec (err, item) =>
      return cb err if err
      cb null, item

  countTasksForProcessDefinitionId: (processDefinitionId, options = {},cb) =>
    @models.Task.count {processDefinitionId : processDefinitionId}, (err, totalCount) =>
      return cb err if err
      cb null,totalCount

  tasksForBoard: (options = {},cb = ->) =>
    options.offset or= 0
    options.count or= 200

    # TODO: EXCLUDE DELETED

    @models.Task.count  {}, (err, totalCount) =>
      return cb err if err

      # processDefinitionId : processDefinitionId,
      query = @models.Task.find( {taskEnded : false})
      query.sort('-createdAt')

      query.setOptions { skip: options.offset , limit: options.count}
      query.exec (err, items) =>
        return cb err if err
        cb null, new PageResult(items || [], totalCount, options.offset, options.count)

  aggregatedTaskTimesForBoardPerState: (options = {},cb = ->) =>

    # processDefinitionId : processDefinitionId,
    query = @models.Task.find() # ( {taskEnded : false})
    query.select '_id timePerState'
    query.exec (err, items) =>
      return cb err if err

      states = {}

      for x in items
        for key,val of x.timePerState

          state = states[key]
          unless state
            state =  
              count : 0
              totalActiveTime : 0
              totalWaitingTime : 0
              totalTime : 0
            states[key] = state
 
          state.count += 1
          state.totalActiveTime += val.totalActiveTime
          state.totalWaitingTime += val.totalWaitingTime
          state.totalTime += val.totalActiveTime + val.totalWaitingTime

      for state, val of states
        val.totalActiveTime /= val.count
        val.totalWaitingTime /= val.count
        val.totalTime /= val.count
        delete val.count

      cb null, states

  all: (options = {},cb = ->) =>
    # TODO: EXCLUDE DELETED

    @models.Task.count  {}, (err, totalCount) =>
      return cb err if err

      query = @models.Task.find({})
      query.sort('-createdAt')
      query.select(options.select || '_id processDefinitionId state createdAt checkedOutByUserId')
      query.setOptions { skip: options.offset, limit: options.count}
      query.exec (err, items) =>
        return cb err if err
        cb null, new PageResult(items || [], totalCount, options.offset, options.count)

  allforDay: (dayDate,options = {},cb = ->) =>
    @models.Task.count  {}, (err, totalCount) =>
      return cb err if err

      query = @models.Task.find({})
      #query.sort('-createdAt')

      start = dayDate
      end = new Date()
      end.setDate(start.getDate()+1)
      end.setHours(0)
      end.setMinutes(0)
      end.setSeconds(0)
      end.setMilliseconds(0)

      console.log "Working against: #{start} and #{end}"

      query.where('createdAt').gte(start).lt(end)
      query.select(options.select || '_id processDefinitionId state createdAt checkedOutByUserId')
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
    @models.Task.findOne {checkedOutByUserId : userId, onHold : false}, (err,item) =>
      return cb err if err
      cb null, item

  ###
  Retrieve a single processDefinition-item through it's id
  ###
  get: (taskId,options = {}, cb = ->) =>
    @models.Task.findOne _id : taskId, (err,item) =>
      return cb err if err
      cb null, item

  ###
  Retrieve a single processDefinition-item through it's id
  ###
  delete: (taskId,options = {}, cb = ->) =>
    @models.Task.remove _id : taskId, (err) =>
      return cb err if err
      cb null

  patch: (taskId, obj = {}, options={}, cb = ->) =>
    @models.Task.findOne _id : taskId, (err,item) =>
      return cb err if err
      return cb new errors.NotFound("/tasks/#{taskId}") unless item

      _.extendFiltered item, UPDATE_FIELDS, obj

      item.markModified('timePerState')  if obj.timePerState 

      item.save (err) =>
        return cb err if err
        cb null, item


