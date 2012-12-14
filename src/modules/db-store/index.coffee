###
Storage functionality for modeista-api
###

Store = require('./store')

module.exports =
  Store: Store
  store: (settings = {}) ->
    new Store(settings)