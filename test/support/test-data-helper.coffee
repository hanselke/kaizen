_ = require 'underscore'
request = require 'request'
qs = require 'querystring'

class TestDataHelper
  constructor: (@app) ->

  createUser: (username,password,cb) =>
    data = 
      username : username
      password : password
      primaryEmail : "#{username}@test.com"

    @app.identityStore.users.create data, (err,user) =>
      return cb err if err
      cb(null,user)


module.exports = (app) -> new TestDataHelper(app)
