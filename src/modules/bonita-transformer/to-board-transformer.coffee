_ = require 'underscore-ext'

###
Transforms raw data to the one that is sent to the client.
###
module.exports = (processDefinition,processInstances) ->
  result =
    lanes: []

  adMap = {}

  for activityDefinition in processDefinition.activities?.ActivityDefinition
    if  activityDefinition.description && 
        _.isString(activityDefinition.description) &&
        activityDefinition.description.length > 0 && 
        activityDefinition.uuid && 
        activityDefinition.uuid.value
      newLane = 
          label: activityDefinition.description || ""
          name: activityDefinition.name || "" 
          id: activityDefinition.uuid.value
          totalTime : 13422
          totalCost: 34.2
          beforeTime : 10000
          afterTime: 3422
          cards: []
      result.lanes.push newLane
      adMap[activityDefinition.uuid.value] = newLane
       
  ###
  result.lanes.push
    label : "Done"
    name : 'done'
    cards: []
  ###

  #console.log "ADMAP"
  #console.log JSON.stringify(_.keys(adMap))

  for instance in processInstances?.ProcessInstance
    console.log "ONE INSTANCE #{instance.instanceUUID.value}"
    #console.log JSON.stringify(instance)

    for activity in instance.activities?.ActivityInstance
        activityDefinitionUUID = activity.activityDefinitionUUID?.value
        if true #activity.state is "READY"
          console.log "ACTIVITY DEFINITION: #{activityDefinitionUUID}"
          myLane = adMap[activityDefinitionUUID] # || _.last( result.lanes)

          if myLane
            myLane.cards.push
              id : activity.uuid?.value
              desc : activity.label
              #html : activity.description
              ready : activity.state?.toUpperCase() is "READY" 
              state : activity.state
              processInstance : instance.instanceUUID.value
              totalTime : 3522
              totalCost: 4.1
              beforeTime : 50
              afterTime: 3472


  result

