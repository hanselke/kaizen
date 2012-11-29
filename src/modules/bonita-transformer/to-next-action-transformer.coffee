_ = require 'underscore-ext'

###
Transforms raw data to the one that is sent to the client.
###
module.exports = (taskList,bonitaBaseUrl) ->
  result = 
    task : null

  console.log "INPUT: #{JSON.stringify(taskList)}"

  if _.isObject taskList && _.keys(taskList).length > 0
    result.task = taskList
  else if _.isArray taskList
    result.task = _.first taskList

  if result.task
    result.taskUUID = result.task.uuid?.value
    result.formUrl = "#{bonitaBaseUrl}?mode=app&task=#{result.taskUUID}" 

  result

