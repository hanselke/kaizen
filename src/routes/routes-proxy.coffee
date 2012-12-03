_ = require 'underscore'
async = require 'async'
winston = require 'winston'
errors = require 'some-errors'
request = require 'request'
qs = require 'querystring'

module.exports = class RoutesProxy

  constructor:(settings,@servicesBonita) ->
    _.extend @,settings
    throw new Error("app parameter is required") unless @app
    throw new Error "servicesBonita parameter is required" unless @servicesBonita

  setupLocals: () =>

  setupRoutes: () =>
    @app.all '/proxy/*', @getProxy


  getProxy:(req,res,next) =>
    console.log "GOT THIS ONE #{req.path}"
    @proxy req,res,"admin","bpm", req.path.substr(6)

  proxy: (req,res, username,password,url) =>
    targetUrl = "#{@servicesBonita.baseUrl}#{url}"
    @login  username,password,(err,j) =>
      return res.end 500 if err
      
      optionsFinal =
        url : targetUrl
        method : req.method
        jar : j
      
      request[req.method.toLowerCase()] optionsFinal, (err,response,body) =>
        res.send(body)

  ###
  proxyPost: (req,res, username,password,url) =>
    targetUrl = "http://simplerelevance.com#{url}"
    @login  username,password,(err,j) =>
      return res.end 500 if err

      optionsFinal =
        url : targetUrl
        method : req.method
        body : req.body
        Accept : 'application/json'
        headers:
          'Content-Type': 'application/json'
        jar : j

      request.post optionsFinal, (err,response,body) =>
        res.send(body)
  ###
    
  login: (username,password,cb) =>
    j = request.jar()
    optionsGet = 
      url :"#{@servicesBonita.baseUrl}/console/login.jsp"
      jar : j
    request.get optionsGet , (err,response,body) =>
      cb err if err
      # Look for id='csrfmiddlewaretoken' name='csrfmiddlewaretoken' value='ed502ea2276d10d873dddeb9956302f3'
      # post this + username + password to same url
      #ma =  body.match /name='csrfmiddlewaretoken' value='([abcdef0123456789]*)'/g
      
      #token = ma[0].replace("name='csrfmiddlewaretoken'","").replace("value='","").replace("'","").replace(" ","")
      #console.log JSON.stringify(token)
      token = ''

      optionsPost = 
        url : "#{@servicesBonita.baseUrl}/security/credentialsencryption"
        body: qs.stringify( {next: '/', csrfmiddlewaretoken : token, username : username, password: password})
        'Content-Type' : 'application/x-www-form-urlencoded'
        jar : j
      request.post optionsPost, (err,response,body) =>
        cb err if err
        #console.log "LOGIN RESULT #{body}"
      
        cb null,j
