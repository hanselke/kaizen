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


    #backoffice: [],
    #sales: [],
    #purchasing: [],
    #done: []


  result.lanes.push
    label : "Done"
    name : 'done'
    cards: []

  result.lanes[0].cards.push
    id : "C1"
    desc : "this is a card"
    html : "<p>Hello</p>"
    ready : "Ready"
  result

