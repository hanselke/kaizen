fs = require 'fs'
_ = require 'underscore'
App = require '../../lib/app'
request = require 'request'
qs = require 'querystring'
async = require 'async'
mongoskin = require 'mongoskin'
bonitaMockServer = require './bonita-mock-server'
testDataHelper = require './test-data-helper'
config = require 'nconf'
path = require 'path'


class Helper
  port: 8002

  openBusinessApp : null

  testData: () ->
    testDataHelper(@openBusinessApp)

  
  cleanDatabase : (cb) =>

    console.log "CLEANING Database #{@database}"

    collections = ['oauthaccesstokens','oauthapps','oauthclients','organizations','users']
    removeCollection = (name,cb) =>
      @mongo.collection(name).remove {}, (err) =>
        cb()

    async.forEach collections ,removeCollection, cb

  start: (obj = {}, done) =>
    _.defaults obj, { }
    config.file file: path.join(__dirname, '../../config/env/test.json')

    @mongo = mongoskin.db(config.get('services:db'), safe: true)
    @openBusinessApp =  @openBusinessApp || new App {}
    

    stuff = []

    stuff.push (cb) =>
      @cleanDatabase(cb)
    stuff.push (cb) =>
      bonitaMockServer(8010,cb)
    stuff.push (cb) =>
      @openBusinessApp.start @port, cb

    async.series stuff, done

  stop: (done) =>
    if @openBusinessApp
      @openBusinessApp.stop =>
        @openBusinessApp = null
        done()
    else
      done()

module.exports = new Helper()
