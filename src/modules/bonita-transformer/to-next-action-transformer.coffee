_ = require 'underscore-ext'

###
Transforms raw data to the one that is sent to the client.
###

module.exports = (taskUUID,bonitaBaseUrl) ->

  result =
    taskUUID : taskUUID
    taskFormURL : "#{bonitaBaseUrl}?mode=app&task=#{taskUUID}"

  result

