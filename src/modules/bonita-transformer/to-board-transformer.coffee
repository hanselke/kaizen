###
Transforms raw data to the one that is sent to the client.
###
module.exports = (process,processInstances) ->
  result =
    lanes: []

  #console.log "WORKING WITH #{JSON.stringify(process?.participants?.ParticipantDefinition)}"
  for participant in process?.participants?.ParticipantDefinition || []
    result.lanes.push
      label: participant.label || ""
      name: participant.name || "" 
      cards: []

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

