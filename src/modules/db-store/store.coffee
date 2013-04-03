mongoose = require 'mongoose'
_ = require 'underscore'
ProcessDefinitionSchema = require './schemas/process-definition-schema'
TaskSchema = require './schemas/task-schema'
RoleSchema = require './schemas/role-schema'
BoardSchema = require './schemas/board-schema'

ProcessDefinitionsMethods = require './methods/process-definition-methods'
TaskMethods = require './methods/task-methods'
RoleMethods = require './methods/role-methods'
BoardMethods = require './methods/board-methods'

module.exports = class Store
  constructor: (@settings = {}) ->
    _.defaults @settings, {}

    @models =
      Role : mongoose.model "Role",RoleSchema
      Task : mongoose.model "Task", TaskSchema
      ProcessDefinition : mongoose.model "ProcessDefinition", ProcessDefinitionSchema
      Board : mongoose.model "Board",BoardSchema

    @processDefinitions = new ProcessDefinitionsMethods @models
    @tasks = new TaskMethods @models
    @roles = new RoleMethods @models
    @boards = new BoardMethods @models