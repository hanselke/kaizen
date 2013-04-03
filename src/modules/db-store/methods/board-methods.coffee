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
Provides methods to interact with boards.
###
module.exports = class BoardMethods
  CREATE_FIELDS = ['_id','name','states','captions']
  UPDATE_FIELDS = ['name','states','captions']

  ###
  Initializes a new instance of the @see BoardMethods class.
  @param {Object} models A collection of models that can be used.
  ###

  ###
  Initializes a new instance of the @see BoardMethods class.
  @param {Object} models A collection of models that can be used.
  ###
  constructor:(@models) ->

  all: (options = {},cb = ->) =>
    # TODO: EXCLUDE DELETED
    options.select or= '_id name states captions'

    @models.Board.count  {}, (err, totalCount) =>
      return cb err if err

      query = @models.Board.find({})
      query.select(options.select)
      query.setOptions { skip: options.offset, limit: options.count}
      query.exec (err, items) =>
        return cb err if err
        cb null, new PageResult(items || [], totalCount, options.offset, options.count)

  ###
  Retrieve a single board-item through it's id
  ###
  get: (boardId, options = {}, cb = ->) =>
    boardId = new ObjectId(boardId.toString())
    query = @models.Board.findOne _id : boardId
    query = query.select(options.select) if options.select && options.select.length > 0
    query.exec cb

  firstBoard: ( options = {}, cb = ->) =>
    query = @models.Board.findOne()
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
  Create a new board
  ###
  create:(objs = {}, actor, cb = ->) =>
    data = {}
    #data.createdBy = actor

    objs.states = objs.states.split(',') if objs.states && _.isString(objs.states)
    objs.captions = objs.captions.split(',') if objs.captions && _.isString(objs.captions)

    _.extendFiltered data, CREATE_FIELDS, objs
    #return cb new errors.UnprocessableEntity("createdBy") unless data.createdBy && data.createdBy.actorId

    model = new @models.Board(data)
    model.save (err) =>
      return cb err if err
      cb(null, model,true)


  destroy: (boardId, options = {}, cb = ->) =>
    @_getItem boardId, options.actor, options.ignoreSecurity, true, (err, item) =>
      return cb err if err
      return cb(null) unless item

      item.remove (err) =>
        return cb err if err
        cb null


  patch: (boardId, obj = {}, options = {}, cb = ->) =>
    @_getItem boardId, options.actor, options.ignoreSecurity, true, (err, item) =>
      return cb err if err
      return cb new errors.NotFound("/boards/#{boardId}") unless item

      obj.states = obj.states.split(',') if obj.states && _.isString(obj.states)
      obj.captions = obj.captions.split(',') if obj.captions && _.isString(obj.captions)

      _.extendFiltered item, UPDATE_FIELDS, obj
      item.save (err) =>
        return cb err if err
        cb null, item

  put: (boardId, obj = {}, options = {}, cb = ->) =>
    @_getItem boardId, options.actor, options.ignoreSecurity,true, (err, item) =>
      return cb err if err
      return cb new errors.NotFound("/boards/#{boardId}") unless item

      obj.states = obj.states.split(',') if obj.states && _.isString(obj.states)
      obj.captions = obj.captions.split(',') if obj.captions && _.isString(obj.captions)

      item[field] = null for field in UPDATE_FIELDS
      _.extendFiltered item, UPDATE_FIELDS, obj

      item.save (err) =>
        return cb err if err
        cb null, item

  _getItem: (boardId, actor, ignoreSecurity, forWrite, cb) =>
    boardId = new ObjectId(boardId.toString())
    @models.Board.findOne _id : boardId, cb
