_ = require 'underscore-ext'
PageResult = require('simple-paginator').PageResult
PageResultInfinite = require('simple-paginator').PageResultInfinite
errors = require 'some-errors'

mongoose = require "mongoose"
ObjectId = mongoose.Types.ObjectId


module.exports = class TaskMethods
  CREATE_FIELDS = ['_id','processDefinitionId','checkedOutByUserId','createdBy','state','processInstanceUUID']
  UPDATE_FIELDS = ['processDefinitionId','checkedOutByUserId','state']

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
