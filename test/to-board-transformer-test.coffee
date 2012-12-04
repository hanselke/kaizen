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

    it "Should have 4 lanes", ->
      should.exist result
      should.exist result.lanes
      result.lanes.should.have.lengthOf 4
