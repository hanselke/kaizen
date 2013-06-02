  stateMachinePackage = require 'openb-app-state-machine'


  module.exports = (processDefinition,cb) ->
    return cb new Error("No valid process defintions found.") unless processDefinition

    smData = null
    try
      smData = JSON.parse(processDefinition.stateMachine)
    catch e
      console.log "Could not parse statemachine for #{processDefinition.name}"
      console.log processDefinition.stateMachine
      return cb new Error("Could not parse JSON State Machine for Process Defintion #{processDefinition.name}")

    sm = stateMachinePackage.stateMachine()
    sm.loadFromObject smData

    cb null,sm
