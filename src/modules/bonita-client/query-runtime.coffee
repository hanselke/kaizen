###
Handles the identity API in bonita
###
module.exports = class QueryRuntime
  constructor:(@client) ->
    throw new Error "client parameter is required" unless @client

  ###
  curl -X POST -d 'options=user:admin' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: application/xml' -H 'Authorization: Basic cmVzdHVzZXI6cmVzdGJwbQ=='  http://ec2-54-251-77-171.ap-southeast-1.compute.amazonaws.com:8080/bonita-server-rest/API/queryRuntimeAPI/getProcessInstances/QA_Data_Entry--1.3
  ###
  getProcessInstances: (processUUID, actAsUser,opts = {},cb = ->) =>
    @client.post "/API/queryRuntimeAPI/getProcessInstances/#{processUUID}",actAsUser,{}, opts, cb


  ###
  curl -X POST -d 'options=user:admin' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: application/xml' -H 'Authorization: Basic cmVzdHVzZXI6cmVzdGJwbQ=='  http://ec2-54-251-77-171.ap-southeast-1.compute.amazonaws.com:8080/bonita-server-rest/API/queryRuntimeAPI/getTaskList/QA_Data_Entry--1.3--2/READY

  curl -X POST -d 'options=user:hansel' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: application/xml' -H 'Authorization: Basic cmVzdHVzZXI6cmVzdGJwbQ==' http://ec2-54-251-77-171.ap-southeast-1.compute.amazonaws.com:8080/bonita-server-rest/API/queryRuntimeAPI/getTaskList/QA_Data_Entry--1.3--2/READY
  curl -X POST -d 'options=user:jack' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: application/xml' -H 'Authorization: Basic cmVzdHVzZXI6cmVzdGJwbQ==' http://ec2-54-251-77-171.ap-southeast-1.compute.amazonaws.com:8080/bonita-server-rest/API/queryRuntimeAPI/getTaskList/QA_Data_Entry--1.3--2/READY
  ###
  getTaskList: (instanceUUID,taskState, actAsUser,opts = {},cb = ->) =>
    @client.post "/API/queryRuntimeAPI/getTaskList/#{instanceUUID}/#{taskState}",actAsUser,{}, opts, cb

  ###
  curl -X POST -d 'options=user:admin' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: application/xml' -H 'Authorization: Basic cmVzdHVzZXI6cmVzdGJwbQ=='  http://ec2-54-251-77-171.ap-southeast-1.compute.amazonaws.com:8080/bonita-server-rest/API/queryRuntimeAPI/getTasks/QA_Data_Entry--1.3--2
  curl -X POST -d 'options=user:hansel' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: application/xml' -H 'Authorization: Basic cmVzdHVzZXI6cmVzdGJwbQ=='  http://ec2-54-251-77-171.ap-southeast-1.compute.amazonaws.com:8080/bonita-server-rest/API/queryRuntimeAPI/getTasks/QA_Data_Entry--1.3--2
  curl -X POST -d 'options=user:martin' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: application/xml' -H 'Authorization: Basic cmVzdHVzZXI6cmVzdGJwbQ=='  http://ec2-54-251-77-171.ap-southeast-1.compute.amazonaws.com:8080/bonita-server-rest/API/queryRuntimeAPI/getTasks/QA_Data_Entry--1.3--2
  ###
  getTasks: (instanceUUID, actAsUser,opts = {},cb = ->) =>
    @client.post "/API/queryRuntimeAPI/getTasks/#{instanceUUID}",actAsUser,{}, opts, cb

  ###
  curl -X POST -d 'options=user:admin' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: application/xml' -H 'Authorization: Basic cmVzdHVzZXI6cmVzdGJwbQ=='  http://ec2-54-251-77-171.ap-southeast-1.compute.amazonaws.com:8080/bonita-server-rest/API/queryRuntimeAPI/getOneTask/READY
  ###  
  getOneTask: (state="READY",actAsUser,opts = {},cb = ->) =>
    @client.post "/API/queryRuntimeAPI/getOneTask/#{state}",actAsUser,{}, opts, cb
