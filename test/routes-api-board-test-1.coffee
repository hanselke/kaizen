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
        body.lanes.should.have.lengthOf 4

        laneStart = body.lanes[0]
        laneA = body.lanes[1]
        laneB = body.lanes[2]
        laneC = body.lanes[3]

        ###
        {"lanes":[{"label":"Shift Manager Approval","name":"Approve1","id":"QA_Data_Entry--1.3--Approve1","totalTime":13422,"totalCost":34.2,"executionTime":10000,"waitingTime":3422,"cards":[]},{"label":"Production Manager Approval","name":"Approve2","id":"QA_Data_Entry--1.3--Approve2","totalTime":13422,"totalCost":34.2,"executionTime":10000,"waitingTime":3422,"cards":[]},{"label":"QA Checks","name":"Enter_Floor_Data","id":"QA_Data_Entry--1.3--Enter_Floor_Data","totalTime":13422,"totalCost":34.2,"executionTime":10000,"waitingTime":3422,"cards":[{"id":"QA_Data_Entry--1.3--2--Enter_Floor_Data--ita760b542-c98b-4134-829a-b73f22b7e07a--mainActivityInstance--noLoop","desc":"Enter Floor Data","ready":true,"state":"READY","processInstance":"QA_Data_Entry--1.3--2","totalTime":3522,"totalCost":4.1,"executionTime":50,"waitingTime":3472}]}]}
        ###
        laneA.should.have.property 'label', 'Shift Manager Approval'
        laneA.should.have.property 'name', 'Approve1'
        laneA.should.have.property 'id', 'QA_Data_Entry--1.3--Approve1'
        laneA.should.have.property 'totalTime'
        laneA.should.have.property 'totalCost'
        laneA.should.have.property 'executionTime'
        laneA.should.have.property 'waitingTime'
        laneA.should.have.property 'cards'
        laneA.cards.should.have.lengthOf 0

        laneB.should.have.property 'label', 'Production Manager Approval'
        laneB.should.have.property 'name', 'Approve2'
        laneB.should.have.property 'id', 'QA_Data_Entry--1.3--Approve2'
        laneB.should.have.property 'totalTime'
        laneB.should.have.property 'totalCost'
        laneB.should.have.property 'executionTime'
        laneB.should.have.property 'waitingTime'
        laneB.should.have.property 'cards'
        laneB.cards.should.have.lengthOf 0

        laneC.should.have.property 'label', 'QA Checks'
        laneC.should.have.property 'name', 'Enter_Floor_Data'
        laneC.should.have.property 'id', 'QA_Data_Entry--1.3--Enter_Floor_Data'
        laneC.should.have.property 'totalTime'
        laneC.should.have.property 'totalCost'
        laneC.should.have.property 'executionTime'
        laneC.should.have.property 'waitingTime'
        laneC.should.have.property 'cards'
        laneC.cards.should.have.lengthOf 2
        should.exist laneC.cards[0]
        laneCcard0 = laneC.cards[0]
        laneCcard1 = laneC.cards[1]

        laneCcard0.should.have.property "id","QA_Data_Entry--1.3--2--Enter_Floor_Data--ita760b542-c98b-4134-829a-b73f22b7e07a--mainActivityInstance--noLoop"
        laneCcard0.should.have.property "desc","Enter Floor Data"
        laneCcard0.should.have.property "ready",true
        laneCcard0.should.have.property "state","READY"
        laneCcard0.should.have.property "processInstance","QA_Data_Entry--1.3--2"
        laneCcard0.should.have.property "totalTime"
        laneCcard0.should.have.property "totalCost"
        laneCcard0.should.have.property "executionTime"
        laneCcard0.should.have.property "waitingTime"

        laneCcard1.should.have.property "id","QA_Data_Entry--1.3--4--Enter_Floor_Data--it1355b6fc-47af-47fd-86cf-62be9e552c51--mainActivityInstance--noLoop"
        laneCcard1.should.have.property "desc","Enter Floor Data"
        laneCcard1.should.have.property "ready",true
        laneCcard1.should.have.property "state","READY"
        laneCcard1.should.have.property "processInstance","QA_Data_Entry--1.3--4"
        laneCcard1.should.have.property "totalTime"
        laneCcard1.should.have.property "totalCost"
        laneCcard1.should.have.property "executionTime"
        laneCcard1.should.have.property "waitingTime"

        done()
