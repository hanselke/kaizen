_ = require 'underscore-ext'

###
Transforms raw data to the one that is sent to the client.
###
module.exports = (taskList,bonitaBaseUrl) ->
  result = 
    task : null

  if _.isObject taskList
    result.task = taskList
  else if _.isArray taskList
    result.task = _.first task

  if result.task
    result.taskUUID = taskList.uuid?.value
    result.formUrl = "#{bonitaBaseUrl}?mode=app&task=#{result.taskUUID}" 

  result

