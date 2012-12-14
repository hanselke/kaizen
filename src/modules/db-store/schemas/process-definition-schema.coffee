_ = require 'underscore'
mongoose = require 'mongoose'
pluginTimestamp = require "mongoose-plugins-timestamp"
pluginCreatedBy = require "mongoose-plugins-created-by"
pluginDeleteParanoid = require "mongoose-plugins-delete-paranoid"
pluginTagsSimple = require "mongoose-plugins-tags-simple"
pluginAccessibleBy = require "mongoose-plugins-accessible-by"
errors = require 'some-errors'


module.exports = ProcessDefinitionSchema = new mongoose.Schema
      name: 
        type: String
        trim: true
        match: /.{2,30}/
        required: true
      description:
        type: String
        default : () -> ''
        trim: true
        match: /.{0,1000}/
      bonitaProcessName: 
        type: String
        trim: true
        match: /.{2,100}/
        required: true


    , strict: true

ProcessDefinitionSchema.plugin pluginTimestamp.timestamps
ProcessDefinitionSchema.plugin pluginCreatedBy.createdBy, isRequired : true
ProcessDefinitionSchema.plugin pluginDeleteParanoid.deleteParanoid

ProcessDefinitionSchema.methods.toRest = (baseUrl, actor) ->
  res =
    url : "#{baseUrl}/process-definitions/#{@_id}"
    id : @_id
    name: @name
    description: @description
    bonitaProcessName: @bonitaProcessName
    createdBy : @createdBy
    createdAt : @createdAt
    updatedAt : @updatedAt
    isDeleted : @isDeleted || false
    deletedAt : @deletedAt || null
  res


