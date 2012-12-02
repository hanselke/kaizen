_ = require 'underscore'
request = require 'request'
qs = require 'querystring'

class HtmlRequestHelper
  port: 8002

  postHtml: (path, bodyObj = {}, options = {}, cb) =>
    reqOptions =
      url: "http://localhost:#{@port}#{path}"
      body: qs.stringify bodyObj
      headers :
        'content-type' : 'application/x-www-form-urlencoded'
        # 'Accept' : 'text/html'
    reqOptions.followRedirect = false if options.noFollowRedirect

    request.post reqOptions, (err, res, body) ->
      cb err, res, body, res.statusCode

  putHtml: (path, bodyObj = {}, options = {}, cb) =>
    reqOptions =
      url: "http://localhost:#{@port}#{path}"
      body: qs.stringify bodyObj
      headers :
        'content-type' : 'application/x-www-form-urlencoded'
        # 'Accept' : 'text/html'
    reqOptions.followRedirect = false if options.noFollowRedirect

    request.put reqOptions, (err, res, body) ->
      cb err, res, body, res.statusCode

  deleteHtml: (path, options = {}, cb) =>
    reqOptions =
      url: "http://localhost:#{@port}#{path}"
      headers :
        'content-type' : 'application/x-www-form-urlencoded'
        # 'Accept' : 'text/html'
    reqOptions.followRedirect = false if options.noFollowRedirect

    request.put  reqOptions, (err, res, body) ->
      cb err, res, body, res.statusCode

  ##
  ## NEW CODE BELOW
  ##
  getHtml: (path, options = {}, cb) =>

    query = options.query || {}

    headers =
      'Accept' : 'text/html'

    url = "http://localhost:#{@port}#{path}"

    queryString = qs.stringify(query)
    url += "?#{queryString}" if queryString

    reqOptions =
      url: url
      headers : headers
    reqOptions.followRedirect = false if options.noFollowRedirect

    request.get reqOptions, (err, res, body) ->
        cb err, res, body, res.statusCode

  options: (path, cb) =>
    params =
      url : "http://localhost:#{@port}#{path}"
      method : 'OPTIONS'

    request params, (err, res, body) ->
      cb err, res, body, res.statusCode

  ###
  IT helpers
  ###

  itHtml200:(route) =>
    it 'should respond with 200', (done) =>
      @getHtml route, null, (err, res, body, status) ->
        status.should.equal(200)
        done(null)

  itHtml302:(route) =>
    it 'should respond with 302 redirect', (done) =>
      @getHtml route, noFollowRedirect : true, (err, res, body, status) ->
        status.should.equal(302)
        done(null)

  itHtml401:(route) =>
    it 'should respond with 401', (done) =>
      @getHtml route, noFollowRedirect : true, (err, res, body, status) ->
        status.should.equal(401)
        done(null)

  itHtml404:(route) =>
    it 'should respond with 404', (done) =>
      @getHtml route, noFollowRedirect : true, (err, res, body, status) ->
        status.should.equal(404)
        done(null)

module.exports = new HtmlRequestHelper()
