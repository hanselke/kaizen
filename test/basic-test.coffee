should = require 'should'
helper = require './support/helper'

describe 'WHEN testing the home page', ->
  before (done) ->
    helper.start null, done
  after ( done) ->
    helper.stop done

  describe 'app.routes.root', ->
    it 'should exist', ->
      should.exist helper.app.routes.root
