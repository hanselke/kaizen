###
Storage functionality for modeista-api
###

StateMachine = require('./state-machine')

module.exports =
  StateMachine: StateMachine
  stateMachine: (settings = {}) ->
    new StateMachine(settings)