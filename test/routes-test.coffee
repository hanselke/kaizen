should = require 'should'
helper = require './support/helper'
htmlRequestHelper = require './support/html-request-helper'

describe 'WHEN testing the routes', ->
  
  before (done) ->
    helper.start null, done
  after ( done) ->
    helper.stop done

  describe '/app', ->
    it 'should redirect', (done) ->
      htmlRequestHelper.getHtml '/app', noFollowRedirect : true, (err,res, body, status) ->
        return next err if err
        status.should.equal(302) # Not logged in, redirect
        # Match that we redirect to /users/sign-in
        done()

  describe '/app', ->
    it 'should return a rendered view', (done) ->
      htmlRequestHelper.getHtml '/app', noFollowRedirect : true, (err,res, body, status) ->
        return next err if err
        status.should.equal(302) # Not logged in, redirect
        should.exist body
        # TODO: Match for specific markers to be sure it is the correct result
        done()
