fs = require 'fs'
_ = require 'underscore'
App = require '../../lib/app'
request = require 'request'
qs = require 'querystring'
async = require 'async'
mongoskin = require 'mongoskin'
bonitaMockServer = require './bonita-mock-server'


class Helper
  port: 8002

  openBusinessApp : null

  fixturePath: (fileName) =>
    "#{__dirname}/../fixtures/#{fileName}"

  tmpPath: (fileName) =>
    "#{__dirname}/../tmp/#{fileName}"

  cleanTmpFiles: (fileNames) =>
    for file in fileNames
      try
        fs.unlinkSync @tmpPath(file)
      catch ignore

  loadJsonFixture: (fixtureName) =>
    data = fs.readFileSync @fixturePath(fixtureName), "utf-8"
    JSON.parse data
  
  start: (obj = {}, done) =>
    _.defaults obj, { }

    @openBusinessApp =  @openBusinessApp || new App {}
    

    stuff = []
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
