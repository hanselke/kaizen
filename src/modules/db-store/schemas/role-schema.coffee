_ = require 'underscore'
mongoose = require 'mongoose'
pluginTimestamp = require "mongoose-plugins-timestamp"
errors = require 'some-errors'
ObjectId = mongoose.Schema.ObjectId

module.exports = RoleSchema = new mongoose.Schema
      name:
        type: String
        required: true
        unique: true
    , strict: true


RoleSchema.plugin pluginTimestamp.timestamps

RoleSchema.pre 'save', (next) ->
  @name = (@name || '').toLowerCase()

  next()
