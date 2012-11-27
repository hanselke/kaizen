request = require 'request'
_ = require 'underscore'
qs = require 'querystring'
asyncParser = require('libxml-to-js')

###
Sample requests
curl -X POST -d 'options=user:admin' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: application/xml' -H 'Authorization: Basic cmVzdHVzZXI6cmVzdGJwbQ=='  http://ec2-54-251-77-171.ap-southeast-1.compute.amazonaws.com:8080/bonita-server-rest/API/identityAPI/getAllUsers

admin:bpm


curl -X POST -d 'options=user:admin' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: application/xml' -H 'Authorization: Basic cmVzdHVzZXI6cmVzdGJwbQ=='  http://ec2-54-251-77-171.ap-southeast-1.compute.amazonaws.com:8080/bonita-server-rest/API/queryDefinitionAPI/getProcesses

Retrieve board data for that process
curl -X POST -d 'options=user:admin' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: application/xml' -H 'Authorization: Basic cmVzdHVzZXI6cmVzdGJwbQ=='  http://ec2-54-251-77-171.ap-southeast-1.compute.amazonaws.com:8080/bonita-server-rest/API/queryRuntimeAPI/getProcessInstances/QA_Data_Entry--1.2

Retrieve the uuid for the active process with that name
curl -X POST -d 'options=user:admin' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: application/xml' -H 'Authorization: Basic cmVzdHVzZXI6cmVzdGJwbQ=='  http://ec2-54-251-77-171.ap-southeast-1.compute.amazonaws.com:8080/bonita-server-rest/API/queryDefinitionAPI/getLastProcess/QA_Data_Entry

###


Identity = require './identity'
QueryRuntime = require './query-runtime'
QueryDefinition = require './query-definition'
Runtime = require './runtime'

module.exports = class Client
  constructor: (@endpoint,@username,@password, @options = {}) ->
    @endpoint = @_cleanEndpoint(@endpoint)
    throw new Error("Endpoint required") unless @endpoint && @endpoint.length > 0
    throw new Error("Username required") unless @username && @username.length > 0
    throw new Error("Password required") unless @password && @password.length > 0

    @options =  {}
    _.defaults @options,
            maxCacheItems: 1000
            headers: {}
    @cache = {}

    @identity  = new Identity @
    @queryRuntime = new QueryRuntime @
    @queryDefinition = new QueryDefinition @
    @runtime = new Runtime @

  _cleanEndpoint: (endpoint) =>
    return null unless endpoint
    endpoint.replace /\/+$/, ""

  _parseXml: (xml,cb) =>
    if xml and xml.length > 0
      try
        asyncParser xml, (err,body) =>
          #console.log "PARSED: #{JSON.stringify(err)} RES: #{JSON.stringify(body)}"
          return cb err if err # Parsing error
          cb null, body
      catch e
        #console.log "Error: #{JSON.stringify(e)}"
        cb new Error("Invalid Body Content \n#{xml}"), null
    else
      cb null,null

  _handleResult: (res, bodyBeforeXml, callback) =>
      #console.log "GOT THIS: #{bodyBeforeXml}"
      return callback new errors.AccessDenied("") if res && res.statusCode is 401 or res.statusCode is 403

      @_parseXml bodyBeforeXml, (err,body) =>
        if res && !(res.statusCode >= 200 && res.statusCode < 300)
          callback new Error(if body then body.message else "Request failed.")
        else
          callback null, body, res.statusCode


  _getAuth: () =>
    new Buffer("#{@username}:#{@password}").toString('base64')

  _reqWithData: (method, path, actAsUser, data = {},opt, callback) =>

    headers =
      'Content-Type': 'application/x-www-form-urlencoded'
      'Accept' : 'application/xml'
      'authorization' : "Basic #{@_getAuth()}"

    _.extend headers, @options.headers

    data.options = "user:admin" 
    #data.options = "user:#{actAsUser}" if actAsUser 

    console.log "INVOKING #{method} #{@endpoint}#{path}"
    console.log "    DATA #{qs.stringify data}"

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


  post: (path, actAsUser, data, opt = {}, callback) =>
    @_reqWithData "POST", path,actAsUser, data,  opt, callback

