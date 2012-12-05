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
  curl -X POST -d 'options=user:jack' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: application/xml' -H 'Authorization: Basic cmVzdHVzZXI6cmVzdGJwbQ==' http://ec2-54-251-77-171.ap-southeast-1.compute.amazonaws.com:8080/bonita-server-rest/API/queryRuntimeAPI/getTaskList/QA_Data_Entry--1.51--6/READY
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
  curl -X POST -d 'options=user:hansel' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: application/xml' -H 'Authorization: Basic cmVzdHVzZXI6cmVzdGJwbQ=='  http://ec2-54-251-77-171.ap-southeast-1.compute.amazonaws.com:8080/bonita-server-rest/API/queryRuntimeAPI/getOneTask/READY
  curl -X POST -d 'options=user:admin' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: application/xml' -H 'Authorization: Basic cmVzdHVzZXI6cmVzdGJwbQ=='  http://ec2-54-251-77-171.ap-southeast-1.compute.amazonaws.com:8080/bonita-server-rest/API/queryRuntimeAPI/getOneTask/READY
  curl -X POST -d 'options=user:james' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: application/xml' -H 'Authorization: Basic cmVzdHVzZXI6cmVzdGJwbQ=='  http://ec2-54-251-77-171.ap-southeast-1.compute.amazonaws.com:8080/bonita-server-rest/API/queryRuntimeAPI/getOneTask/READY
  curl -X POST -d 'options=user:jack' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: application/xml' -H 'Authorization: Basic cmVzdHVzZXI6cmVzdGJwbQ=='  http://ec2-54-251-77-171.ap-southeast-1.compute.amazonaws.com:8080/bonita-server-rest/API/queryRuntimeAPI/getOneTask/READY
  ###  
  getOneTask: (state="READY",actAsUser,opts = {},cb = ->) =>
    @client.post "/API/queryRuntimeAPI/getOneTask/#{state}",actAsUser,{}, opts, cb

  ###
  curl -X POST -d 'options=user:admin' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: application/xml' -H 'Authorization: Basic cmVzdHVzZXI6cmVzdGJwbQ=='  http://ec2-54-251-77-171.ap-southeast-1.compute.amazonaws.com:8080/bonita-server-rest/API/queryRuntimeAPI/getTask/QA_Data_Entry--1.51--6--_1_Enter_Floor_Data--it88afc64a-4758-4672-ab21-36884963d1f5--mainActivityInstance--noLoop
  ###  
  getTask: (taskUUID, actAsUser,opts = {},cb = ->) =>
    @client.post "/API/queryRuntimeAPI/getTask/#{taskUUID}",actAsUser,{}, opts, cb

  
  ###
  curl -X POST -d 'options=user:admin' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: application/xml' -H 'Authorization: Basic cmVzdHVzZXI6cmVzdGJwbQ=='  http://ec2-54-251-77-171.ap-southeast-1.compute.amazonaws.com:8080/bonita-server-rest/API/queryRuntimeAPI/getTaskCandidates/QA_Data_Entry--1.51--6--_1_Enter_Floor_Data--it88afc64a-4758-4672-ab21-36884963d1f5--mainActivityInstance--noLoop
  ###  
  getTaskCandidates: (taskUUID, actAsUser,opts = {},cb = ->) =>
    @client.post "/API/queryRuntimeAPI/getTaskCandidates/#{taskUUID}",actAsUser,{}, opts, cb

  ###
    curl -X POST -d 'options=user:jack' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: application/xml' -H 'Authorization: Basic cmVzdHVzZXI6cmVzdGJwbQ=='  http://ec2-54-251-77-171.ap-southeast-1.compute.amazonaws.com:8080/bonita-server-rest/API/queryRuntimeAPI/getOneTaskByProcessInstanceUUIDAndActivityState/QA_Data_Entry--1.51--7/READY
  ###  
  getOneTaskByProcessInstanceUUIDAndActivityState: (processInstanceUUID,state="READY", actAsUser,opts = {},cb = ->) =>
    @client.post "/API/queryRuntimeAPI/getOneTaskByProcessInstanceUUIDAndActivityState/#{processInstanceUUID}/#{state}",actAsUser,{}, opts, cb

