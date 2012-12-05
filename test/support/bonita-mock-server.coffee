express = require 'express'
fixtureHelper  = require './fixture-helper'

class BonitaServerMock
  constructor:(@port) ->
    @mockServer = express()

    @mockServer.post '/API/queryDefinitionAPI/getProcesses',(req,res) =>
      res.send fixtureHelper.loadFixture 'case1-get-processes.xml'

    @mockServer.post '/API/queryRuntimeAPI/getProcessInstances/:processUUID',(req,res) =>
      res.send fixtureHelper.loadFixture 'case1-get-process-instances.xml'


    @mockServer.post '/API/queryRuntimeAPI/getOneTask/:state',(req,res) =>
      res.send fixtureHelper.loadFixture 'case4-step1-get-one-task.xml'

    @mockServer.post '/API/runtimeAPI/executeTask/:taskUUID/:assign',(req,res) =>
      res.send ''

    @mockServer.post '/API/queryRuntimeAPI/getTask/:taskUUID',(req,res) =>
      res.send fixtureHelper.loadFixture 'case4-step3-get-task.xml'


    @mockServer.post '/API/queryRuntimeAPI/getOneTaskByProcessInstanceUUIDAndActivityState/:processInstanceId/:state',(req,res) =>
      res.send fixtureHelper.loadFixture 'case4-step4-get-one-task-by-process-instance-uuid-and-activity-state.xml'
    #@mockServer.post '/API/queryRuntimeAPI/getTaskList/:instanceUUID/:taskState',(req,res) =>
    #  res.send fixtureHelper.loadFixture 'case1-get-tasklist.xml'

    @mockServer.post '/API/runtimeAPI/startTask/:taskUUID/:assign',(req,res) =>
      res.send ""


    @server = @mockServer.listen port

  stop:() =>
    @server.close() if @server

bonitaServerMock = null

module.exports = (port, done = () ->) ->
  unless bonitaServerMock
    bonitaServerMock = new BonitaServerMock(port)
  done()
