_ = require 'underscore'

require('pkginfo')(module, 'version')

toBoardTransformer = require('./to-board-transformer')
toNextActionTransformer = require('./to-next-action-transformer')

module.exports =
  toBoard: toBoardTransformer
  toNextAction : toNextActionTransformer
