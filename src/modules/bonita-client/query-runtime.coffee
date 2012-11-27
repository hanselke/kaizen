###
Handles the identity API in bonita
###
module.exports = class QueryRuntime
  constructor:(@client) ->
    throw new Error "client parameter is required" unless @client

  getProcessInstances: (processUUID, actAsUser,opts = {},cb = ->) =>
    @client.post "/API/queryRuntimeAPI/getProcessInstances/#{processUUID}",actAsUser, opts, cb

