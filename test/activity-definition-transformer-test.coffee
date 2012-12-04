should = require 'should'
helper = require './support/helper'
_ = require 'underscore'
fixtureHelper = require './support/fixture-helper'

activityDefinitionTransformer = require '../lib/modules/bonita-transformer/activity-definition-transformer'

activityDefinitions = fixtureHelper.loadJsonFixture 'case2-activity-definitions.json'


describe 'WHEN testing the route api tasks', ->
  before (done) ->
    helper.start null, done

  after ( done) ->
    helper.stop done

  describe 'working with activity defintions', ->
    it "should not be null", ->
      should.exist activityDefinitions

  describe 'when mapping', ->
    result = _.map(activityDefinitions,activityDefinitionTransformer)

    it "Should have 8 elements", ->
      should.exist result
      result.should.have.lengthOf 8

    it "element 0", ->
      element = result[0]
      should.exist element
      element.should.have.property 'id','QA_Data_Entry--1.51--Assign_enter_floor_data'
      element.should.have.property 'name','Assign_enter_floor_data'
      element.should.have.property 'label','Assign enter floor data'
      element.should.have.property 'order'
      element.should.have.property 'description',''
      element.should.have.property 'isStart', false
      element.should.have.property 'isEnd', false
      element.should.have.property 'group','enter_floor_data'
      element.should.have.property 'isAssign', true
      element.should.have.property 'isState', false

    it "element 1", ->
      element = result[1]
      should.exist element
      element.should.have.property 'id','QA_Data_Entry--1.51--_2_Approve1'
      element.should.have.property 'name','_2_Approve1'
      element.should.have.property 'label','2 Approve1'
      element.should.have.property 'order',2
      element.should.have.property 'description','Shift Manager Approval'
      element.should.have.property 'isStart', false
      element.should.have.property 'isEnd', false
      element.should.have.property 'group','approve1'
      element.should.have.property 'isAssign', false
      element.should.have.property 'isState', true

    it "element 2", ->
      element = result[2]
      should.exist element
      element.should.have.property 'id','QA_Data_Entry--1.51--_3_Approve2'
      element.should.have.property 'name','_3_Approve2'
      element.should.have.property 'label','3 Approve2'
      element.should.have.property 'order',3
      element.should.have.property 'description','Production Manager Approval'
      element.should.have.property 'isStart', false
      element.should.have.property 'isEnd', false
      element.should.have.property 'group','approve2'
      element.should.have.property 'isAssign', false
      element.should.have.property 'isState', true

    it "element 3", ->
      element = result[3]
      should.exist element
      element.should.have.property 'id','QA_Data_Entry--1.51--End___Entry_approved'
      element.should.have.property 'name','End___Entry_approved'
      element.should.have.property 'label','End - Entry approved'
      element.should.have.property 'order'
      element.should.have.property 'description',''
      element.should.have.property 'isStart', false
      element.should.have.property 'isEnd', true
      element.should.have.property 'group',''
      element.should.have.property 'isAssign', false
      element.should.have.property 'isState', false

    it "element 4", ->
      element = result[4]
      should.exist element
      element.should.have.property 'id','QA_Data_Entry--1.51--_1_Enter_Floor_Data'
      element.should.have.property 'name','_1_Enter_Floor_Data'
      element.should.have.property 'label','1 Enter Floor Data'
      element.should.have.property 'order',1
      element.should.have.property 'description','QA Checks'
      element.should.have.property 'isStart', false
      element.should.have.property 'isEnd', false
      element.should.have.property 'group','enter_floor_data'
      element.should.have.property 'isAssign', false
      element.should.have.property 'isState', true

    it "element 5", ->
      element = result[5]
      should.exist element
      element.should.have.property 'id','QA_Data_Entry--1.51--Start'
      element.should.have.property 'name','Start'
      element.should.have.property 'label','Start'
      element.should.have.property 'order',9999
      element.should.have.property 'description',''
      element.should.have.property 'isStart', true
      element.should.have.property 'isEnd', false
      element.should.have.property 'group',''
      element.should.have.property 'isAssign', false
      element.should.have.property 'isState', false

    it "element 6", ->
      element = result[6]
      should.exist element
      element.should.have.property 'id','QA_Data_Entry--1.51--Assign_approve1'
      element.should.have.property 'name','Assign_approve1'
      element.should.have.property 'label','Assign approve1'
      element.should.have.property 'order'
      element.should.have.property 'description',''
      element.should.have.property 'isStart', false
      element.should.have.property 'isEnd', false
      element.should.have.property 'group','approve1'
      element.should.have.property 'isAssign', true
      element.should.have.property 'isState', false

    it "element 7", ->
      element = result[7]
      should.exist element
      element.should.have.property 'id','QA_Data_Entry--1.51--Assign_approve2'
      element.should.have.property 'name','Assign_approve2'
      element.should.have.property 'label','Assign approve2'
      element.should.have.property 'order'
      element.should.have.property 'description',''
      element.should.have.property 'isStart', false
      element.should.have.property 'isEnd', false
      element.should.have.property 'group','approve2'
      element.should.have.property 'isAssign', true
      element.should.have.property 'isState', false

