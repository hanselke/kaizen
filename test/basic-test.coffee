should = require 'should'
helper = require './support/helper'

describe 'WHEN testing the home page', ->
  before (done) ->
    helper.start null, done
  after ( done) ->
    helper.stop done

  describe 'openBusinessApp.routes.root', ->
    it 'should exist', ->
      should.exist helper.openBusinessApp.routes.root
  describe 'openBusinessApp.routes.adminUsers', ->
    it 'should exist', ->
      should.exist helper.openBusinessApp.routes.adminUsers
  describe 'openBusinessApp.routes.routesUsers', ->
    it 'should exist', ->
      should.exist helper.openBusinessApp.routes.routesUsers
  describe 'openBusinessApp.routes.routesApi', ->
    it 'should exist', ->
      should.exist helper.openBusinessApp.routes.routesApi
  describe 'openBusinessApp.routes.routesApp', ->
    it 'should exist', ->
      should.exist helper.openBusinessApp.routes.routesApp

