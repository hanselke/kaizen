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

  ###
  curl -X POST -d 'options=user:admin' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: application/xml' -H 'Authorization: Basic cmVzdHVzZXI6cmVzdGJwbQ=='  http://ec2-54-251-77-171.ap-southeast-1.compute.amazonaws.com:8080/bonita-server-rest/API/queryDefinitionAPI/getProcesses
  ###
  getProcesses: (actAsUser,opts = {},cb = ->) =>
    @client.post "/API/queryDefinitionAPI/getProcesses",actAsUser, {}, opts, cb


