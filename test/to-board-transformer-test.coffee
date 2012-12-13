should = require 'should'
helper = require './support/helper'
_ = require 'underscore'
fixtureHelper = require './support/fixture-helper'

toBoardTransformer = require '../lib/modules/bonita-transformer/to-board-transformer'

processDefinitions = fixtureHelper.loadJsonFixture 'case2-process-definitions.json'
processInstances = fixtureHelper.loadJsonFixture 'case2-process-instances.json'

describe 'WHEN testing the route api tasks', ->
  before (done) ->
    helper.start null, done

  after ( done) ->
    helper.stop done

  describe 'working with processDefinitions', ->
    it "should not be null", ->
      should.exist processDefinitions

  describe 'working with process instances', ->
    it "should not be null", ->
      should.exist processInstances

  describe 'when mapping', ->
    result = toBoardTransformer(processDefinitions,processInstances)
    console.log JSON.stringify(result)
    it "Should have 4 lanes", ->
      should.exist result
      should.exist result.lanes
      result.lanes.should.have.lengthOf 4

    it "lane 0", ->
      lane = result.lanes[0]
      should.exist lane
      lane.should.have.property "label","Start"
      lane.should.have.property "name",""
      lane.should.have.property "order",0
      lane.should.have.property "id", ""
      lane.should.have.property "totalTime",0
      lane.should.have.property "totalCost",0
      lane.should.have.property "executionTime",0
      lane.should.have.property "waitingTime",0
      lane.should.have.property "activityDefinitions"
      lane.should.have.property "cards"
      lane.activityDefinitions.should.have.lengthOf 2
      lane.cards.should.have.lengthOf 2

      card0 = lane.cards[0]
      should.exist card0
      card0.should.have.property "id","QA_Data_Entry--1.51--2--Assign_enter_floor_data--it6441d631-41fd-4e87-8ae4-d7adb8ac8445--mainActivityInstance--noLoop"
      card0.should.have.property "desc","Enter floor data" # Transform this to Enter floor data
      card0.should.have.property "ready",true
      card0.should.have.property "state","READY"
      card0.should.have.property "processInstance","QA_Data_Entry--1.51--2"
      card0.should.have.property "activityDefinitionUUID","QA_Data_Entry--1.51--Assign_enter_floor_data"
      card0.should.have.property "totalTime",0
      card0.should.have.property "totalCost",0
      card0.should.have.property "executionTime",0
      card0.should.have.property "waitingTime",0

      card1 = lane.cards[1]
      should.exist card1
      card1.should.have.property "id","QA_Data_Entry--1.51--3--Assign_enter_floor_data--itd25cbe54-d4ce-452a-92c8-edf215b62727--mainActivityInstance--noLoop"
      card1.should.have.property "desc","Enter floor data" # Transform this to Enter floor data
      card1.should.have.property "ready",true
      card1.should.have.property "state","READY"
      card1.should.have.property "processInstance","QA_Data_Entry--1.51--3"
      card1.should.have.property "activityDefinitionUUID","QA_Data_Entry--1.51--Assign_enter_floor_data"
      card1.should.have.property "totalTime",0
      card1.should.have.property "totalCost",0
      card1.should.have.property "executionTime",0
      card1.should.have.property "waitingTime",0



    it "lane 1", ->
      lane = result.lanes[1]
      should.exist lane
      lane.should.have.property "label","QA Checks"
      lane.should.have.property "name","_1_Enter_Floor_Data"
      lane.should.have.property "order",1
      lane.should.have.property "id", "QA_Data_Entry--1.51--_1_Enter_Floor_Data"
      lane.should.have.property "totalTime",0
      lane.should.have.property "totalCost",0
      lane.should.have.property "executionTime",0
      lane.should.have.property "waitingTime",0
      lane.should.have.property "activityDefinitions"
      lane.should.have.property "cards"
      lane.activityDefinitions.should.have.lengthOf 2
      lane.cards.should.have.lengthOf 0

    it "lane 2", ->
      lane = result.lanes[2]
      should.exist lane
      lane.should.have.property "label","Shift Manager Approval"
      lane.should.have.property "name","_2_Approve1"
      lane.should.have.property "order",2
      lane.should.have.property "id", "QA_Data_Entry--1.51--_2_Approve1"
      lane.should.have.property "totalTime",0
      lane.should.have.property "totalCost",0
      lane.should.have.property "executionTime",0
      lane.should.have.property "waitingTime",0
      lane.should.have.property "activityDefinitions"
      lane.should.have.property "cards"
      lane.activityDefinitions.should.have.lengthOf 2
      lane.cards.should.have.lengthOf 0

    it "lane 3", ->
      lane = result.lanes[3]
      should.exist lane
      lane.should.have.property "label","Production Manager Approval"
      lane.should.have.property "name","_3_Approve2"
      lane.should.have.property "order",3
      lane.should.have.property "id", "QA_Data_Entry--1.51--_3_Approve2"
      lane.should.have.property "totalTime",0
      lane.should.have.property "totalCost",0
      lane.should.have.property "executionTime",0
      lane.should.have.property "waitingTime",0
      lane.should.have.property "activityDefinitions"
      lane.should.have.property "cards"
      lane.activityDefinitions.should.have.lengthOf 2
      lane.cards.should.have.lengthOf 0

