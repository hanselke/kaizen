fs = require 'fs'
_ = require 'underscore'
App = require '../../lib/app'
request = require 'request'
qs = require 'querystring'
async = require 'async'

class Helper
  port: 8002

  app : null

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

    obj.cleanDatabase = true if obj.initDatabase

    @app =  @app || new App {}

    stuff = []

    stuff.push (cb) =>
      @app.start @port, cb

    async.series stuff, done

  stop: (done) =>
    if @app
      @app.stop ->
        @app = null
        done()
    else
      done()

module.exports = new Helper()
