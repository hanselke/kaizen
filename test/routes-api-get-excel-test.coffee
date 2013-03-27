should = require 'should'
helper = require './support/helper'
htmlRequestHelper = require './support/html-request-helper'
fromRequestHelper = require './support/form-request-helper'

taskId = null

describe 'WHEN testing the route api getExcel route', ->
  
  before (done) ->
    helper.start null, () ->
      helper.testData().createUser "martin","123456", () ->
        fromRequestHelper.postForm '/users/sign-in', {username: "martin", password: "123456"}, (err) ->
          return done err if err
          done()

  after ( done) ->
    helper.stop done

  ###
  describe 'CREATE TASK AND STUFF', ->
    it 'should create it', (done) ->
        helper.openBusinessApp

        done()

  describe '/api/tasks/:taskId/excel', ->
    it 'should return a csv', (done) ->
      htmlRequestHelper.getHtml "/api/tasks/#{taskId}/excel", {}, (err,res, body, status) ->
        return next err if err
        status.should.equal(200)
        should.exist body

        console.log "-----"
        console.log body
        console.log "-----"
        done()
  ###