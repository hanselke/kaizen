should = require 'should'
helper = require './support/helper'
htmlRequestHelper = require './support/html-request-helper'
fromRequestHelper = require './support/form-request-helper'

describe 'WHEN testing the route api tasks', ->
  before (done) ->
    helper.start null, done

  after ( done) ->
    helper.stop done