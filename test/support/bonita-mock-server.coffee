express = require 'express'

class BonitaServerMock
  constructor:(@port) ->
    @mockServer = express()

    ###
    @mockServer.get '/token-infos/:token', (req, res) =>
      if req.params.token is "goodtoken"
        res.json goodTokenResult
      else if req.params.token is "othertoken"
        res.json otherTokenResult
      else if req.params.token is "withprofile"
        res.json withProfileResult
      else if req.params.token is "badtoken"
        res.json 404, null
      else
        res.json 404, null

    @mockServer.get '/users/5016d77fd7f1b9a74800002c', (req, res) =>
      res.json withProfileGetUserResult

    @mockServer.get '/entities/fsd324', (req,res) =>
      res.json 404,null

    @mockServer.post '/identities/facebook', (req, res) =>
      res.json 201, {"url":"http://identity.modeista.com/users/504d11c3ed69fe2956000006","id":"504d11c3ed69fe2956000006","username":"martinwqsAfXibxGi","description":"","identities":[{"url":"http://identity.modeista.com/users/504d11c3ed69fe2956000006/identities/504d11c3ed69fe2956000007","id":"504d11c3ed69fe2956000007","provider":"facebook","key":"679841881","v1":"370348486367451","v2":"BAAFQ1Hn5GNsBAO6GZCZAnZAdCBYZAGZAKwZAQdRZC4Yw95WlV7lCQFrCfnvIoau9dSCmrzINFnHdOZCJWgMlrP1ZAZAy93rWjp3q8O1qPdAPuX9cpOOpyguWqnurnKbyR85UQZD","providerType":"oauth"}],"profileLinks":[],"userImages":[],"emails":[],"roles":[],"data":{},"stats":{},"resourceLimits":[],"createdAt":"2012-09-09T22:01:39.317Z","updatedAt":"2012-09-09T22:04:37.304Z","isDeleted":false,"deletedAt":null,"token":{"accessToken":"504d1275ed69fe2956000010","refreshToken":"4RpJX5pQyXuerUmWxS2SuUfW1cGNzSv6dA8lytGqdfJBAUFZbYdA97dPsNqyqKlTNtpfuxMtHz25JjQE"}}

    
    ###
    @server = @mockServer.listen port

  stop:() =>
    @server.close() if @server

bonitaServerMock = null

module.exports = (port, done = () ->) ->
  unless bonitaServerMock
    bonitaServerMock = new BonitaServerMock(port)
  done()
