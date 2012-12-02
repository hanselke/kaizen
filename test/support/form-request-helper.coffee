
_ = require 'underscore'
request = require 'request'
qs = require 'querystring'

class FormRequestHelper
  port: 8002


  postForm: (path,bodyString, cb) =>
    params =
      url: "http://localhost:#{@port}#{path}"
      headers:
        'Accept' : 'application/json'
      body: qs.stringify( bodyString)
      method : "POST"

    params.headers['Content-Type'] = 'application/x-www-form-urlencoded'

    request params, (err, res, body) ->
        status = if res then res.statusCode else 0
        cb(err, res, body, status)

module.exports = new FormRequestHelper()