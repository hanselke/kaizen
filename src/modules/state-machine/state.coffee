_ = require 'underscore'

module.exports = class State
  constructor: (data = {}) ->
    _.extend @,data

