_ = require 'underscore'
stateMachinePackage = require '../../modules/state-machine'

###
Takes an array of object with
state :..
processDefinitionId : ..

as input and calls a callback with a map

processDefinitonToStateMap[processDefintionId] = {
  stateName: [roles]  
}

as output. Those roles are allowed to transition into the next state.

###
module.exports = (statesAndProcessDefinitionIds = [],dbStore,cb) ->
  stateMachinesForProcessDefinitionId = {}

  processDefinitonToStateMap = {}

  dbStore.processDefinitions.all {count: 1000,select: '_id stateMachine'}, (err,processDefinitionsResult) ->
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
        stateMachinesForProcessDefinitionId[processDefinition._id.toString()] = sm


    for xx in statesAndProcessDefinitionIds
      processDefinitonToStateMap[xx.processDefinitionId.toString()] = {}

    for xx in statesAndProcessDefinitionIds
      sm = stateMachinesForProcessDefinitionId[xx.processDefinitionId.toString()]

      map = processDefinitonToStateMap[xx.processDefinitionId.toString()]
      map[xx.state] = if sm then sm.getRolesForState(xx.state) else []
      # Not perfect, but...

    cb null, processDefinitonToStateMap
