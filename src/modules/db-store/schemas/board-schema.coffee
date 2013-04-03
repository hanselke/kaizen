_ = require 'underscore'
mongoose = require 'mongoose'
pluginTimestamp = require "mongoose-plugins-timestamp"
errors = require 'some-errors'
ObjectId = mongoose.Schema.ObjectId

module.exports = BoardSchema = new mongoose.Schema
      name:
        type: String
        required: true
        unique: true
      states: # The states as mapped by the role
        type: [String] 
        default: () -> []

    , strict: true


BoardSchema.plugin pluginTimestamp.timestamps

###
RoleSchema.pre 'save', (next) ->
  @name = (@name || '').toLowerCase()

  next()
###
