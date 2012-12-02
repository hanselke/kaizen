should = require 'should'
helper = require './support/helper'
htmlRequestHelper = require './support/html-request-helper'
fromRequestHelper = require './support/form-request-helper'

describe 'WHEN testing the route api tasks', ->
  before (done) ->
    helper.start null, () ->
      helper.testData().createUser "martin","123456", () ->
        fromRequestHelper.postForm '/users/sign-in', {username: "martin", password: "123456"}, (err) ->
          return done err if err
          done()

  after ( done) ->
    helper.stop done

  describe '/api/tasks', ->
    it 'should redirect', (done) ->
      htmlRequestHelper.getHtml '/api/tasks/?procInstUUID=QA_Data_Entry--1.3--4', {}, (err,res, body, status) ->
        return next err if err
        status.should.equal(200)
        should.exist body
        body = JSON.parse(body)
        should.exist body
        body.should.have.property 'taskFormURL','http://ec2-54-251-77-171.ap-southeast-1.compute.amazonaws.com:8080/bonita?mode=app&task=QA_Data_Entry--1.3--2--Enter_Floor_Data--ita760b542-c98b-4134-829a-b73f22b7e07a--mainActivityInstance--noLoop'
        body.should.have.property 'taskUUID','QA_Data_Entry--1.3--2--Enter_Floor_Data--ita760b542-c98b-4134-829a-b73f22b7e07a--mainActivityInstance--noLoop'

        done()
