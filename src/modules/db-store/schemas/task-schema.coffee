_ = require 'underscore'
mongoose = require 'mongoose'
pluginTimestamp = require "mongoose-plugins-timestamp"
pluginCreatedBy = require "mongoose-plugins-created-by"
pluginDeleteParanoid = require "mongoose-plugins-delete-paranoid"
pluginTagsSimple = require "mongoose-plugins-tags-simple"
errors = require 'some-errors'
ObjectId = mongoose.Schema.ObjectId

module.exports = TaskSchema = new mongoose.Schema
      processDefinitionId: 
        type: ObjectId
        required: true
      checkedOutByUserId:
        type: String
        #unique: true
        #sparse: true
      data:
        type: mongoose.Schema.Types.Mixed
        default: () -> {}

      processInstanceUUID:
        type: String
        unique: true
        default: -> new Date().toString()
      activeTaskUUID:
        type: String
      activeActivityName:
        type: String
      totalAbsoluteTimeSpent:
        type: Number
        default: 0
      totalTimeSpent:
        type: Number
        default: 0
      checkedOutDate:
        type: Date

      state: 
        type: String
        default: ''
        required: true
      stateCompleted: 
        type: Boolean
        default: false
      nextState:
        type: String
        default: null
      name:
        type: String
    , strict: true


TaskSchema.plugin pluginTimestamp.timestamps
TaskSchema.plugin pluginCreatedBy.createdBy, isRequired : true

TaskSchema.methods.toRest = (baseUrl, actor) ->
  res =
    url : "#{baseUrl}/tasks/#{@_id}"
    id : @_id
    processDefinitionId: @processDefinitionId
    checkedOutByUserId: @checkedOutByUserId
    createdBy : @createdBy
    createdAt : @createdAt
    updatedAt : @updatedAt
    processInstanceUUID : @processInstanceUUID
  res


