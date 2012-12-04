_ = require 'underscore-ext'
moment = require 'moment'

processDefinitionToLaneOrder = require './process-definition-to-lane-order'
activityDefinitionTransformer = require './activity-definition-transformer'

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


  ###
  console.log "ALL ACTIVITIES@@@"
  console.log JSON.stringify(processDefinition.activities.ActivityDefinition)
  console.log "ALL ACTIVITIES@@@@"

  console.log "ALL ACTIVITIES"
  console.log JSON.stringify(_.map(processDefinition.activities?.ActivityDefinition,activityDefinitionTransformer))
  console.log "ALL ACTIVITIES"
  ###

  ###
  Here is what needs to happen now:
  1. We need to build the lanes
  We have 1 + n lanes, where the first one is the start lane, and the rest are, sorted by order, the isState activity definitons
  ###

  activityDefinitions = _.map(processDefinition.activities?.ActivityDefinition,activityDefinitionTransformer)
  adMap = {}

  result.lanes.push
        label: "Start"
        name: ""
        order: 0
        activityDefinitions: []
        id: ''
        totalTime : 0
        totalCost: 0
        beforeTime : 0
        afterTime: 0
        cards: []

  for activityDefinition in _.filter(_.sortBy(activityDefinitions,(x) -> x.order ) , (x) -> x.isState)
    result.lanes.push
        label: activityDefinition.description || ""
        name: activityDefinition.name || "" 
        order: activityDefinition.order
        id: activityDefinition.id
        totalTime : 0
        totalCost: 0
        beforeTime : 0
        afterTime: 0
        activityDefinitions: [activityDefinition]
        cards: []

  ###
  2. We need to assign activityDefinition's to the right lanes,starting wiht start and end.
  ###
  _.first(result.lanes).activityDefinitions.push _.find(activityDefinitions,(x) -> x.isStart)
  _.last(result.lanes).activityDefinitions.push _.find(activityDefinitions,(x) -> x.isEnd)

  ###
  3. And now the fun part, we go from element 1 to n and find the matching assign+group,
  and put that in lane n - 1
  ###

  for i in [1..result.lanes.length - 1]
    group = _.first(result.lanes[i].activityDefinitions).group
    activityDefinitionForGroup = _.find(activityDefinitions,(x) -> x.isAssign and x.group is group)
    result.lanes[i - 1].activityDefinitions.push activityDefinitionForGroup

  ###
  4. Now we assign it to the map
  ###
  for lane in result.lanes
    for activityDefinition in lane.activityDefinitions
      adMap[activityDefinition.id] = lane



  ###
  for activityDefinition in processDefinition.activities?.ActivityDefinition
    if  activityDefinition.description && 
        _.isString(activityDefinition.description) &&
        activityDefinition.description.length > 0 && 
        activityDefinition.uuid && 
        activityDefinition.uuid.value

      newLane = 
          label: activityDefinition.description || ""
          name: activityDefinition.name || "" 
          order: orderFromActivityDefinition(activityDefinition)
          id: activityDefinition.uuid.value
          totalTime : 0
          totalCost: 0
          beforeTime : 0
          afterTime: 0
          activityDefinitionIds: [activityDefinition.uuid.value]
          cards: []
      result.lanes.push newLane
      adMap[activityDefinition.uuid.value] = newLane

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
  ###

  ###
  console.log "ADMAP"
  console.log JSON.stringify(_.keys(adMap))
  console.log "ADMAP"
  ###
  processInstances = processInstances.ProcessInstance

  ###
  console.log "$$$$$$$$$$$"
  console.log JSON.stringify(processInstances)
  console.log "$$$$$$$$$$$"
  ###

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

