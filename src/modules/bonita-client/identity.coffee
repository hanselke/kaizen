###
Handles the identity API in bonita
###
module.exports = class Identity
  constructor:(@client) ->
    throw new Error "client parameter is required" unless @client

  getAllUsers: (actAsUser,opts = {},cb = ->) =>
    @client.post "/API/identityAPI/getAllUsers",actAsUser,{}, opts, cb

