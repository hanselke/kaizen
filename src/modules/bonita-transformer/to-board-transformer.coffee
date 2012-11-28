_ = require 'underscore-ext'

###
Transforms raw data to the one that is sent to the client.
###
module.exports = (processes,process,processInstances) ->
  result =
    lanes: []

  adMap = {}

  for processDefinition in processes?.ProcessDefinition
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
            cards: []
        result.lanes.push newLane
        adMap[activityDefinition.uuid.value] = newLane
       

  result.lanes.push
    label : "Done"
    name : 'done'
    cards: []

  for instance in processInstances?.ProcessInstance
    for activity in instance.activities?.ActivityInstance
        result.lanes[0].cards.push
          id : activity.uuid?.value
          desc : activity.label
          html : activity.description
          ready : activity.state?.toUpperCase() is "READY" 
          state : activity.state

  result

