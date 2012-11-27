_ = require 'underscore'

require('pkginfo')(module, 'version')

toBoardTransformer = require('./to-board-transformer')

module.exports =
  toBoard: toBoardTransformer
