###
Transforms raw data to the one that is sent to the client.
###
module.exports = (process,processInstances) ->
  result =
    lanes: []

  console.log "EEE"
  #console.log "WORKING WITH #{JSON.stringify(process?.participants?.ParticipantDefinition)}"
  for participant in process?.participants?.ParticipantDefinition || []
    result.lanes.push
      label: participant.label || ""
      name: participant.name || "" 
      cards: []

  console.log "TTTT"

    #backoffice: [],
    #sales: [],
    #purchasing: [],
    #done: []

  #console.log "ROOT: #{JSON.stringify(processInstances)}"
  result.lanes.push
    label : "Done"
    name : 'done'
    cards: []

  console.log "YY"

  for instance in processInstances?.ProcessInstance
    console.log "XX"
    for activity in instance.activities?.ActivityInstance
      console.log "YY"

      result.lanes[0].cards.push
        id : activity.uuid?.value
        desc : activity.label
        html : activity.description
        ready : activity.state?.toUpperCase() is "READY" 
        state : activity.state

  result

