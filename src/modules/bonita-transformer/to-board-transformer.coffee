_ = require 'underscore-ext'
moment = require 'moment'

activityDefinitionTransformer = require './activity-definition-transformer'

orderFromActivityDefinition = (activityDefinition) ->
  return 9999 unless activityDefinition.label && activityDefinition.label.length > 0 && activityDefinition.label.indexOf(" ") > 0
  label = activityDefinition.label.substr(0,activityDefinition.label.indexOf(" "))
  parseInt(label,0)


isInReadyState = (activityDefinitionUUID,activityDefinitions = []) ->
  return true unless activityDefinitionUUID
  activityDefinition = _.find(activityDefinitions, (x) -> x.id is activityDefinitionUUID)
  return true unless activityDefinition
  activityDefinition.isAssign || activityDefinition.isStart || activityDefinition.isEnd

cleanDesc = (label) ->
  return label unless label && label.length > "Assign ".length && label.indexOf("Assign ") is 0
  label = label.substr "Assign ".length
  label[0].toUpperCase() + label.substr(1)

###
Transforms raw data to the one that is sent to the client.
###
module.exports = (processDefinition,processInstances) ->
  result =
    lanes: []

  console.log 'LLLLL 0 '
  #console.log "JSON #{JSON.stringify(processDefinition)}"

  ###
  Here is what needs to happen now:
  1. We need to build the lanes
  We have 1 + n lanes, where the first one is the start lane, and the rest are, sorted by order, the isState activity definitons
  ###

  activityDefinitions = _.map(processDefinition.activities?.ActivityDefinition,activityDefinitionTransformer)
  adMap = {}

  console.log 'LLLLL 1 '

  result.lanes.push
        label: "Start"
        name: ""
        order: 0
        activityDefinitions: []
        id: ''
        totalTime : 0
        totalCost: 0
        executionTime : 0
        waitingTime: 0
        cards: []

  sortedActivityDefinitionsForState = _.sortBy(_.filter(activityDefinitions, (x) -> x.isState),(x) -> x.order ) 

  console.log 'LLLLL 2 '

  for activityDefinition in sortedActivityDefinitionsForState
    result.lanes.push
        label: activityDefinition.description || ""
        name: activityDefinition.name || "" 
        order: activityDefinition.order
        id: activityDefinition.id
        totalTime : 0
        totalCost: 0
        executionTime : 0
        waitingTime: 0
        activityDefinitions: [activityDefinition]
        cards: []

  console.log 'LLLLL 3 '

  ###
  2. We need to assign activityDefinition's to the right lanes,starting wiht start and end.
  ###
  _.first(result.lanes).activityDefinitions.push _.find(activityDefinitions,(x) -> x.isStart)
  _.last(result.lanes).activityDefinitions.push _.find(activityDefinitions,(x) -> x.isEnd)

  console.log 'LLLLL 4 '

  ###
  3. And now the fun part, we go from element 1 to n and find the matching assign+group,
  and put that in lane n - 1
  ###

  for i in [1..result.lanes.length - 1]
    group = _.first(result.lanes[i].activityDefinitions).group
    activityDefinitionForGroup = _.find(activityDefinitions,(x) -> x.isAssign and x.group is group)
    result.lanes[i - 1].activityDefinitions.push activityDefinitionForGroup

  console.log 'LLLLL 5 '

  ###
  4. Now we assign it to the map
  ###
  for lane in result.lanes

    for activityDefinition in lane.activityDefinitions || [] when activityDefinition
      adMap[activityDefinition.id] = lane

  console.log 'LLLLL 6'
  ###
  5. Now we work with process instances.
  ###
  pp = []
  if processInstances
    if _.isArray processInstances.ProcessInstance
      pp = processInstances.ProcessInstance
    else if processInstances.ProcessInstance
      pp = [processInstances.ProcessInstance]

    for instance in pp

      activity = null
      aaXX = instance.activities?.ActivityInstance
      if aaXX && _.isArray(aaXX)
        dd = (d for d in aaXX when d.state != "FINISHED")
        activity = _.last(dd)
      else if aaXX
        activity = aaXX

      #for activity in instance.activities?.ActivityInstance
      if activity
          activityDefinitionUUID = activity.activityDefinitionUUID?.value
          if true #activity.state isnt "FINISHED"
            myLane = adMap[activityDefinitionUUID] # || _.last( result.lanes)


            #use moment here
            ###
                      startedDate= moment( activity.startedDate || 0) #1354080180430
            lastUpdate = moment(activity.lastUpdate || 0)   #1354088710758

            ###

            startedDate= activity.startedDate || 0 #1354080180430
            lastUpdate = activity.lastUpdate || 0  #1354088710758
            totalTime = lastUpdate - startedDate
            executionTime = 0
            waitingTime = 0

            if startedDate is 0 || lastUpdate is 0 || totalTime > 10000000000
              totalTime = 0
              executionTime = 0
              waitingTime = 0

            instanceStateUpdates = activity.instanceStateUpdates

            if _.isObject( instanceStateUpdates) && _.keys(instanceStateUpdates).length > 0
              instanceStateUpdates = [instanceStateUpdates.InstanceStateUpdate]
            
            if instanceStateUpdates && _.isArray instanceStateUpdates && instanceStateUpdates.length > 0
              executionTime = _.first(instanceStateUpdates).date - activity.startedDate
              waitingTime = activity.lastUpdate - _.first(instanceStateUpdates).date

            myLane = result.lanes[0] unless myLane

            if myLane
              myLane.cards.push
                id : activity.uuid?.value
                desc : cleanDesc( activity.label)
                #html : activity.description
                ready : isInReadyState(activity.uuid?.value,activityDefinitions) # activity.state?.toUpperCase() is "READY" 
                state : activity.state
                processInstance : instance.instanceUUID.value
                activityDefinitionUUID : activityDefinitionUUID
                totalTime :  totalTime
                totalCost: 0
                executionTime : executionTime
                waitingTime: waitingTime

    for lane in result.lanes
      for card in lane.cards
        lane.totalTime = lane.totalTime + card.totalTime
        lane.totalCost = lane.totalCost + card.totalCost
        lane.executionTime = lane.executionTime + card.executionTime
        lane.waitingTime = lane.waitingTime + card.totalTime



  result

