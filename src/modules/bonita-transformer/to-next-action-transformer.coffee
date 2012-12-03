_ = require 'underscore-ext'

###
Transforms raw data to the one that is sent to the client.
###

module.exports = (nextTask,bonitaBaseUrl) ->

  result = {}


  console.log "=====RR=="
  console.log "INPUT: #{JSON.stringify(nextTask)}"
  console.log "=====RR=="

  if nextTask && nextTask.value
    result.taskUUID = nextTask.value
    result.taskFormURL = "#{bonitaBaseUrl}?mode=app&task=#{result.taskUUID}"

  result



###
module.exports = (taskList,bonitaBaseUrl) ->
  result = 
    task : null


  taskList = taskList.ActivityInstance
  #console.log "======="
  #console.log "INPUT: #{JSON.stringify(taskList)}"
  #console.log "======="

  if _.isObject( taskList) && _.keys(taskList).length > 0
    result.task = taskList
  else if _.isArray taskList
    result.task = _.first taskList

  if result.task
    result.taskUUID = result.task.uuid?.value
    result.taskFormURL = "#{bonitaBaseUrl}?mode=app&task=#{result.taskUUID}" 

  result

###