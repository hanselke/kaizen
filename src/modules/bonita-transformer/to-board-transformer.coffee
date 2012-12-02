_ = require 'underscore-ext'
moment = require 'moment'


convertNodeCollection = (x) ->
  x = x["string"]
  return [] unless x

  if _.isArray(x)
    return _.map x, (y) -> y['#'] 
  else
    return [x]

convertNodeCollectionLower = (x) ->
  _.map( convertNodeCollection(x), (y) -> y.toLowerCase())

getCleanIterationDescriptors = (processDefinition) ->
  descriptors = processDefinition?.iterationDescriptors?["org.ow2.bonita.facade.def.element.impl.IterationDescriptor"]
  return [] unless descriptors && descriptors.length > 0

  result = _.map descriptors, (x) -> 
      {
        otherNodes : convertNodeCollection(x.otherNodes)
        entryNodes : convertNodeCollection(x.entryNodes)
        exitNodes : convertNodeCollection(x.exitNodes)
        otherNodesLower : convertNodeCollectionLower(x.otherNodes)
        entryNodesLower : convertNodeCollectionLower(x.entryNodes)
        exitNodesLower : convertNodeCollectionLower(x.exitNodes)
      }

  result

getIterationDescriptors = (processDefinition) ->
  descriptors = getCleanIterationDescriptors(processDefinition)
  return [] unless descriptors && descriptors.length > 0

  result = []

  currentEntryNode = null
  currentExitNode = null

  for i in [0, descriptors.length - 1]
    
    console.log "DESCRIPTORS===="
    console.log JSON.stringify( descriptors)
    console.log "DESCRIPTORS----"
    
    if currentEntryNode is null
      ###  
        step 1: look for the IterationDescriptor group with an empty <otherNodes>, marked by <otherNodes/>

          this represents the first step of the process
          Look for the <entryNodes> (there should only be 1), and that name is the name of the first activity
          Look for <exitNodes> (should be only 1), and that is the name of the 2nd activity


          You need to store the current process path,
            step1:<EntryNode>
            step2:<ExitNode>

      ###
      n =  _.find descriptors, (x) -> x.otherNodes.length is 0
      descriptors = _.reject descriptors, (x) -> x.otherNodes.length is 0
      currentEntryNode = _.first( n.entryNodes) 
      currentExitNode = _.first(n.exitNodes)
      console.log "NEW ENTRY: #{currentEntryNode}"
      console.log "NEW EXIT: #{currentExitNode}"

      result.push n if n
    else

      ###

    step 2: look within the <otherNodes> group of the other IterationDescriptor , and make sure that it ONLY contains

        1) Step2 from the current process path
        2) Assign_ $exitNode

      add to the current process path,
        step3:Assign_$exitNode
        step4:exitNode

    step 3: look within the <otherNodes> group of the other IterationDescriptor , and make sure that it ONLY contains
        1) Step2-step4 from the current process path
        2) Assign_$exitNode

      add to the current process path,

        step5:Assign_$exitNode
        step6:$exitNode


        with the current process path, see where the human tasks from subgoal1: fits in, then you know how to display them on the board.
      ###
      n =  _.find descriptors, (x) -> 
        return false unless _.contains( x.otherNodesLower, currentExitNode.toLowerCase())
        return false unless _.contains( x.otherNodesLower, "assign_" + _.first( x.exitNodesLower))
        return x.otherNodes.length is 2

      #otherNodes = _.exclude otherNodes, (x) -> true
      if n
        currentEntryNode = _.first(n.entryNodes)
        currentExitNode =  "assign_#{_.first(n.exitNodes) }" 
        console.log "NEW ENTRY: #{currentEntryNode}"
        console.log "NEW EXIT: #{currentExitNode}"

        result.push n

  result

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

  #console.log "ADMAP"
  #console.log JSON.stringify(_.keys(adMap))

  for instance in processInstances?.ProcessInstance

    for activity in instance.activities?.ActivityInstance
        activityDefinitionUUID = activity.activityDefinitionUUID?.value
        if true #activity.state is "READY"
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

          if myLane
            myLane.cards.push
              id : activity.uuid?.value
              desc : activity.label
              #html : activity.description
              ready : activity.state?.toUpperCase() is "READY" 
              state : activity.state
              processInstance : instance.instanceUUID.value
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

  #getIterationDescriptors(processDefinition)

  result

