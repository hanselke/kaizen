request = require 'request'
_ = require 'underscore'
xmlParser = require "libxmljs-easy"
qs = require 'querystring'

###
Sample requests
curl -X POST -d '' -H 'Content-Type: application/xml' -H 'Accept: application/xml' -H 'Authorization: Basic cmVzdHVzZXI6cmVzdGJwbQ=='  http://ec2-54-251-77-171.ap-southeast-1.compute.amazonaws.com:8080/bonita-server-rest/API/identityAPI/getAllUsers


curl -X POST -d 'options=user:admin' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: application/xml' -H 'Authorization: Basic cmVzdHVzZXI6cmVzdGJwbQ=='  http://ec2-54-251-77-171.ap-southeast-1.compute.amazonaws.com:8080/bonita-server-rest/API/identityAPI/getAllUsers

admin:bpm

###
Identity = require './identity'

module.exports = class Client
  constructor: (@endpoint,@username,@password, @options = {}) ->
    @endpoint = @_cleanEndpoint(@endpoint)
    throw new Error("Endpoint required") unless @endpoint && @endpoint.length > 0
    throw new Error("Username required") unless @username && @username.length > 0
    throw new Error("Password required") unless @password && @password.length > 0

    _.defaults @options,
            maxCacheItems: 1000
            headers: {}
    @cache = {}

    @identity  = new Identity @

  _cleanEndpoint: (endpoint) =>
    return null unless endpoint
    endpoint.replace /\/+$/, ""

  _handleResult: (res, bodyBeforeXml, callback) =>
      return callback new errors.AccessDenied("") if res.statusCode is 401 or res.statusCode is 403

      body = null

      #console.log "WE ARE HERE #{bodyBeforeXml}"
      if bodyBeforeXml and bodyBeforeXml.length > 0
        try
          # console.log "GETTING: #{bodyBeforeXml} END GETTING"
          body = xmlParser.parse(bodyBeforeXml)
        catch e
          return callback( new Error("Invalid Body Content"), bodyBeforeXml, res.statusCode)

      return callback(new Error(if body then body.message else "Request failed.")) unless res.statusCode >= 200 && res.statusCode < 300
      callback null, body, res.statusCode

  _getAuth: () =>
    new Buffer("#{@username}:#{password}").toString('base64')

  _reqWithData: (method, path, data = {}, actAsUser,opt, callback) =>

    headers =
      'Content-Type': 'application/x-www-form-urlencoded'
      'Accept' : 'application/xml'
      'authorization' : "Basic #{@_getAuth()}"

    _.extend headers, @options.headers

    data.user = actAsUser if actAsUser

    request
      uri: "#{@endpoint}#{path}"
      headers: headers
      body: if data then qs.stringify data else null
      method: method
      timeout: 2000
     , (err, res, body) =>
       if err
         err.status = res.statusCode
         return callback(err)

       @_handleResult res, body, callback


  post: (path, data, opt = {}, callback) =>
    @_reqWithData "POST", path, data, options, callback

  ###
  patch: (path, data, opt = {}, callback) =>
    @_reqWithData "PATCH", path, data, options, callback

  put: (path, data, opt = {}, callback) =>
    @_reqWithData "PUT", path, data, options, callback



  delete: (path,actAsUser, opt = {}, callback) =>
    headers =
      'Accept' : 'application/xml'
      'authorization' : "Basic #{@_getAuth()}"

    _.extend headers, @options.headers

    request
      uri: "#{@endpoint}#{path}"
      headers: headers
      method: 'DELETE'
     , (err, res, body) =>
        if err
          err.status = res.statusCode
          return callback(err)

        @_handleResult res, body, callback

  get: (path,actAsUser, opt = {}, callback) =>
    if !callback && _.isFunction opt
      callback = opt
      opt = {}

    headers =
      'Accept' : 'application/xml'
      'authorization' : "Basic #{@_getAuth()}"

    _.extend headers, @options.headers

    request
      uri: "#{@endpoint}#{path}"
      headers: headers
      method: 'GET'
     , (err, res, body) =>
       if err
         err.status = res.statusCode
         return callback(err)
       @_handleResult res, body, callback
  ###
