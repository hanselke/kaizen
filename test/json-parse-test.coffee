should = require 'should'
helper = require './support/helper'
fixtureHelper = require './support/fixture-helper'

describe 'WHEN loading some exported form definitions', ->
  before (done) ->
    helper.start null, done
  after ( done) ->
    helper.stop done


  describe 'form67', ->
    it 'should parse', (done) ->
      body = fixtureHelper.loadFixture 'forms/form67.json'
      should.exist body
      parsed = JSON.parse body
      should.exist parsed
      done()


  describe 'form68', ->
    it 'should parse', (done) ->
      body = fixtureHelper.loadFixture 'forms/form68.json'
      should.exist body
      parsed = JSON.parse body
      should.exist parsed
      done()
