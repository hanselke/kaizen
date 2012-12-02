should = require 'should'
helper = require './support/helper'
htmlRequestHelper = require './support/html-request-helper'

describe 'WHEN testing the route api board', ->
  
  before (done) ->
    helper.start null, () ->
      helper.testData().createUser "martin","123456", () ->
        done()

  after ( done) ->
    helper.stop done

  describe '/api/board', ->
    it 'should redirect', (done) ->
      htmlRequestHelper.getHtml '/api/board', {}, (err,res, body, status) ->
        return next err if err
        status.should.equal(200)
        console.log "BODY: #{JSON.stringify(body)}"
        done()
