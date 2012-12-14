mongoose = require 'mongoose'
_ = require 'underscore'
ProcessDefinitionSchema = require './schemas/process-definition-schema'


ProcessDefinitionsMethods = require './methods/process-definitions-methods'

module.exports = class Store
  constructor: (@settings = {}) ->
    _.defaults @settings, {}

    @models =
      ProcessDefinition : mongoose.model "ProcessDefinition", ProcessDefinitionSchema

    @processDefinitions = new ProcessDefinitionsMethods @models
