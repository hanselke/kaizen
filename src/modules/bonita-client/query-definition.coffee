###
Handles the identity API in bonita
###
module.exports = class QueryDefinition
  constructor:(@client) ->
    throw new Error "client parameter is required" unless @client

  getLastProcess: (processName, actAsUser,opts = {},cb = ->) =>
    @client.post "/API/queryDefinitionAPI/getLastProcess/#{processName}",actAsUser, {}, opts, cb

  getProcessActivities: (processDefinitionUUID, actAsUser,opts = {},cb = ->) =>
    @client.post "/API/queryDefinitionAPI/getProcessActivities/#{processDefinitionUUID}",actAsUser, {}, opts, cb
