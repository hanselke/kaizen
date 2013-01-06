should = require 'should'
helper = require './support/helper'
xlsxToForm = require '../lib/modules/xlsx-to-form'

form1Path = "#{__dirname}/./fixtures/form1.xlsx"

form1Path = "#{__dirname}/./fixtures/wb1.xlsx"
layout1Path = "#{__dirname}/./fixtures/form1-layout-raw.json"

describe 'WHEN testing the home page', ->
  before (done) ->
    helper.start null, done
  after ( done) ->
    helper.stop done

  describe 'form', ->
    it 'should load', (done) ->
      xlsxToForm.loadAndConvert form1Path, (err,html) =>
        return done err if err

        console.log ""
        console.log html
        done null


  describe 'layout', ->
    it 'should load', (done) ->
      xlsxToForm.loadAndConvertVba layout1Path, (err,converted) =>
        return done err if err

        console.log ""
        console.log JSON.stringify(converted)
        done null

        