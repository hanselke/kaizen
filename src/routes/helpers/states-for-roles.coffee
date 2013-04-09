_ = require 'underscore'
stateMachinePackage = require '../../modules/state-machine'

module.exports = (roles,dbStore,cb) ->
  statesResult = []

  dbStore.processDefinitions.all {count: 1000,select: 'stateMachine'}, (err,processDefinitionsResult) ->
    return next err if err

    for processDefinition in processDefinitionsResult.items
      smData = null
      try
        smData = JSON.parse(processDefinition.stateMachine)
      catch e
        console.log "Could not parse statemachine for #{processDefinition.name}"
        console.log processDefinition.stateMachine
        # We ignore that.

      if smData
        sm = stateMachinePackage.stateMachine()
        sm.loadFromObject smData

        statesResult = _.union statesResult, sm.getStatesForRoles(roles)

    console.log "States: #{statesResult}"
    cb null, statesResult
