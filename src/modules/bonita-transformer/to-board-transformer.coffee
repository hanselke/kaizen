_ = require 'underscore-ext'
moment = require 'moment'

processDefinitionToLaneOrder = require './process-definition-to-lane-order'

orderFromActivityDefinition = (activityDefinition) ->
  return 9999 unless activityDefinition.label && activityDefinition.label.length > 0 && activityDefinition.label.indexOf(" ") > 0
  label = activityDefinition.label.substr(0,activityDefinition.label.indexOf(" "))
  parseInt(label,0)


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

      console.log "&&&&&&&"
      console.log JSON.stringify(activityDefinition)
      console.log "&&&&&&&"

      newLane = 
          label: activityDefinition.description || ""
          name: activityDefinition.name || "" 
          order: orderFromActivityDefinition(activityDefinition)
          id: activityDefinition.uuid.value
          totalTime : 0
          totalCost: 0
          beforeTime : 0
          afterTime: 0
          cards: []
      result.lanes.push newLane
      adMap[activityDefinition.uuid.value] = newLane
       
  ###
  result.lanes.push
    label : "Done"
    name : 'done'
    cards: []
  ###
  result.lanes = _.sortBy( result.lanes, (x) -> x.order)

  result.lanes.unshift
          label: "Start"
          name: ""
          order: 0
          id: ''
          totalTime : 0
          totalCost: 0
          beforeTime : 0
          afterTime: 0
          cards: []


  console.log "ADMAP ##########"
  console.log JSON.stringify(_.keys(adMap))
  console.log "ADMAP ##########--"

  processInstances = processInstances.ProcessInstance

  console.log "$$$$$$$$$$$"
  console.log JSON.stringify(processInstances)
  console.log "$$$$$$$$$$$"


  for instance in processInstances

    for activity in instance.activities?.ActivityInstance
        activityDefinitionUUID = activity.activityDefinitionUUID?.value
        if activity.state isnt "FINISHED"
          myLane = adMap[activityDefinitionUUID] # || _.last( result.lanes)


          #use moment here
          ###
                    startedDate= moment( activity.startedDate || 0) #1354080180430
          lastUpdate = moment(activity.lastUpdate || 0)   #1354088710758

          ###

          startedDate= activity.startedDate || 0 #1354080180430
          lastUpdate = activity.lastUpdate || 0  #1354088710758
          totalTime = lastUpdate - startedDate
          beforeTime = 0
          afterTime = 0

          if startedDate is 0 || lastUpdate is 0 || totalTime > 10000000000
            totalTime = 0
            beforeTime = 0
            afterTime = 0

          instanceStateUpdates = activity.instanceStateUpdates

          if _.isObject( instanceStateUpdates) && _.keys(instanceStateUpdates).length > 0
            instanceStateUpdates = [instanceStateUpdates.InstanceStateUpdate]
          
          if instanceStateUpdates && _.isArray instanceStateUpdates && instanceStateUpdates.length > 0
            beforeTime = _.first(instanceStateUpdates).date - activity.startedDate
            afterTime = activity.lastUpdate - _.first(instanceStateUpdates).date

          myLane = result.lanes[0] unless myLane

          if myLane
            myLane.cards.push
              id : activity.uuid?.value
              desc : activity.label
              #html : activity.description
              ready : activity.state?.toUpperCase() is "READY" 
              state : activity.state
              processInstance : instance.instanceUUID.value
              activityDefinitionUUID : activityDefinitionUUID
              totalTime :  totalTime
              totalCost: 0
              beforeTime : beforeTime
              afterTime: afterTime

    for lane in result.lanes
      for card in lane.cards
        lane.totalTime = lane.totalTime + card.totalTime
        lane.totalCost = lane.totalCost + card.totalCost
        lane.beforeTime = lane.beforeTime + card.beforeTime
        lane.afterTime = lane.afterTime + card.totalTime



  result

