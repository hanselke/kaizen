mongoose = require 'mongoose'
_ = require 'underscore'
ProcessDefinitionSchema = require './schemas/process-definition-schema'
TaskSchema = require './schemas/task-schema'

ProcessDefinitionsMethods = require './methods/process-definition-methods'
TaskMethods = require './methods/task-methods'

module.exports = class Store
  constructor: (@settings = {}) ->
    _.defaults @settings, {}

    @models =
      Task : mongoose.model "Task", TaskSchema
      ProcessDefinition : mongoose.model "ProcessDefinition", ProcessDefinitionSchema

    @processDefinitions = new ProcessDefinitionsMethods @models
    @tasks = new TaskMethods @models