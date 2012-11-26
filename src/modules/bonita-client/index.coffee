_ = require 'underscore'

require('pkginfo')(module, 'version')

Client = require('./client')

module.exports =
  Client: Client
  client: (options = {}) ->
    new Client options.endpoint,options.username,options.password, options
