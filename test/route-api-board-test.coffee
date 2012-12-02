should = require 'should'
helper = require './support/helper'
htmlRequestHelper = require './support/html-request-helper'
fromRequestHelper = require './support/form-request-helper'

describe 'WHEN testing the route api board', ->
  
  before (done) ->
    helper.start null, () ->
      helper.testData().createUser "martin","123456", () ->
        fromRequestHelper.postForm '/users/sign-in', {username: "martin", password: "123456"}, (err) ->
          return done err if err
          done()

  after ( done) ->
    helper.stop done

  describe '/api/board', ->
    it 'should redirect', (done) ->
      htmlRequestHelper.getHtml '/api/board', {}, (err,res, body, status) ->
        return next err if err
        status.should.equal(200)
        should.exist body
        body = JSON.parse(body)
        should.exist body
        body.should.have.property 'lanes'
        body.lanes.should.have.lengthOf 3

        laneA = body.lanes[0]
        laneB = body.lanes[1]
        laneC = body.lanes[2]

        ###
        {"lanes":[{"label":"Shift Manager Approval","name":"Approve1","id":"QA_Data_Entry--1.3--Approve1","totalTime":13422,"totalCost":34.2,"beforeTime":10000,"afterTime":3422,"cards":[]},{"label":"Production Manager Approval","name":"Approve2","id":"QA_Data_Entry--1.3--Approve2","totalTime":13422,"totalCost":34.2,"beforeTime":10000,"afterTime":3422,"cards":[]},{"label":"QA Checks","name":"Enter_Floor_Data","id":"QA_Data_Entry--1.3--Enter_Floor_Data","totalTime":13422,"totalCost":34.2,"beforeTime":10000,"afterTime":3422,"cards":[{"id":"QA_Data_Entry--1.3--2--Enter_Floor_Data--ita760b542-c98b-4134-829a-b73f22b7e07a--mainActivityInstance--noLoop","desc":"Enter Floor Data","ready":true,"state":"READY","processInstance":"QA_Data_Entry--1.3--2","totalTime":3522,"totalCost":4.1,"beforeTime":50,"afterTime":3472}]}]}
        ###
        laneA.should.have.property 'label', 'Shift Manager Approval'
        laneA.should.have.property 'name', 'Approve1'
        laneA.should.have.property 'id', 'QA_Data_Entry--1.3--Approve1'
        laneA.should.have.property 'totalTime'
        laneA.should.have.property 'totalCost'
        laneA.should.have.property 'beforeTime'
        laneA.should.have.property 'afterTime'
        laneA.should.have.property 'cards'
        laneA.cards.should.have.lengthOf 0

        done()
