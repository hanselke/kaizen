###
Handles the identity API in bonita
###
module.exports = class Identity
  constructor:(@client) ->
    throw new Error "client parameter is required" unless @client

  getAllUsers: (opts = {},cb = ->) =>
    @client.post "/API/identityAPI/getAllUsers", opts, cb

