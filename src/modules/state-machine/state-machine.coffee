_ = require 'underscore'
State = require './state'

module.exports = class StateMachine
  constructor: (@settings = {}) ->
    _.defaults @settings, {}

  loadFromObject: (stateMachineData = {}) =>
    @stateMachineData = stateMachineData
    @stateMachineData.states or= {}
    @stateMachineData.forms or= {}

    @stateMachineData.states.start or= new State({name : 'start',hideFromlane: true})
    @stateMachineData.states.end or= new State({name : 'end',hideFromlane: true})

    for key,val of @stateMachineData.states
      v = val || {}
      _.extend v, {name: key}
      @stateMachineData.states[key] = new State(v)

  ###
  Returns an array of state objects that should be shown in the swim lane.
  ###
  getSwimlanes: =>
    result = []
    result.push val for key,val of @stateMachineData.states when val && !val.hideFromlane
    return result

  ###
  Returns the first state on a new task.
  ###
  getInitialState: =>
    @stateMachineData.initialState || "start"

  getState: (stateName) =>
    @stateMachineData.states[stateName]

  getNextState: (currentState,data = {},cb) =>
    state = @getState(currentState)
    return cb new Error("State '#{currentState}' not found") unless state

    if _.isString(state.transitionToNextState) 
      cb null,@getState(state.transitionToNextState)
    else if _.isObject(state.transitionToNextState) && state.transitionToNextState.fn
      try
        task = {}
        options = {}

        runMe = "var task=JSON.parse('#{JSON.stringify(task)}');var data=JSON.parse('#{JSON.stringify(data)}');var options=JSON.parse('#{JSON.stringify(options)}'); var fn = #{state.transitionToNextState.fn}; fn(task,data,options);"
        console.log "RUNME"
        console.log runMe
        console.log "RUNME-END"
        nextStateName = eval runMe
        return cb new Error ("Failed to evaluate state transition function for #{currentState}") unless nextStateName
        nextState = @getState(nextStateName)
        return cb new Error ("Invalid next state #{nextStateName} after transition function for #{currentState}") unless nextState
        cb null, nextState
      catch e
        cb new Error("Failed to execute state transition code: #{e.message}")
      
    else
      cb new Error("unspecified or wrong state definition")

  getNextStateName: (currentState,data = {},cb) =>
    @getNextState currentState,data, (err,state) =>
      return cb err if err
      cb null, state.name

  getFormForState: (state) =>
    state = @getState(state)
    return null unless state
    return null unless state.formToShow && state.formToShow.length > 0
    @stateMachineData.forms[state.formToShow]

  ###
  Returns an array of states that are allower for a user with the given roles.
  ###
  getStatesForRoles: (roles = []) =>
    result = []

    # Dirty implementation - it's late
    for key,val of @stateMachineData.states when val.allowedRoles && val.allowedRoles.length > 0
      for role in roles
        if _.contains(val.allowedRoles,role)
          result.push key

    _.uniq(result)

  getExcelFieldFromState: (stateName) =>
    state = @getState stateName
    return null unless state
    state.excelField

  existsAsExcelField: (excelFieldName) =>
    for key,val of @stateMachineData.states
      return true if val.excelField is excelFieldName


    false

