###
Handles the identity API in bonita
###
module.exports = class Runtime
  constructor:(@client) ->
    throw new Error "client parameter is required" unless @client

  ###
  curl -X POST -d 'options=user:admin' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: application/xml' -H 'Authorization: Basic cmVzdHVzZXI6cmVzdGJwbQ=='  http://ec2-54-251-77-171.ap-southeast-1.compute.amazonaws.com:8080/bonita-server-rest/API/runtimeAPI/assignTask/QA_Data_Entry--1.2--16--Assign_enter_floor_data--it9f228c2a-3a3e-4889-9dca-28fc00fa1db2--mainActivityInstance--noLoop/admin
  ###
  assignTask: (taskUUID,actorId, actAsUser,opts = {},cb = ->) =>
    @client.post "/API/runtimeAPI/assignTask/#{taskUUID}/#{actorId}",actAsUser,{}, opts, cb

  ###
  curl -X POST -d 'options=user:admin' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: application/xml' -H 'Authorization: Basic cmVzdHVzZXI6cmVzdGJwbQ=='  http://ec2-54-251-77-171.ap-southeast-1.compute.amazonaws.com:8080/bonita-server-rest/API/runtimeAPI/startTask/QA_Data_Entry--1.2--16--Assign_enter_floor_data--it9f228c2a-3a3e-4889-9dca-28fc00fa1db2--mainActivityInstance--noLoop/false
  ###
  startTask: (taskUUID,assign = false, actAsUser,opts = {},cb = ->) =>
    @client.post "/API/runtimeAPI/startTask/#{taskUUID}/#{assign}",actAsUser,{}, opts, cb

  ###
  curl -X POST -d 'options=user:james' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: application/xml' -H 'Authorization: Basic cmVzdHVzZXI6cmVzdGJwbQ=='  http://ec2-54-251-77-171.ap-southeast-1.compute.amazonaws.com:8080/bonita-server-rest/API/runtimeAPI/executeTask/QA_Data_Entry--1.2--16--Assign_enter_floor_data--it9f228c2a-3a3e-4889-9dca-28fc00fa1db2--mainActivityInstance--noLoop/true
  ###
  executeTask: (taskUUID,assign = false, actAsUser,opts = {},cb = ->) =>
    data = {}
    @client.post "/API/runtimeAPI/executeTask/#{taskUUID}/#{assign}",actAsUser,data, opts, cb


  ###
  curl -X POST -d 'options=user:admin' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: application/xml' -H 'Authorization: Basic cmVzdHVzZXI6cmVzdGJwbQ=='  http://ec2-54-251-77-171.ap-southeast-1.compute.amazonaws.com:8080/bonita-server-rest/API/runtimeAPI/startActivity/QA_Data_Entry--1.2--16--Assign_enter_floor_data--it9f228c2a-3a3e-4889-9dca-28fc00fa1db2--mainActivityInstance--noLoop
  ###
  startActivity: (activityUUID, actAsUser,opts = {},cb = ->) =>
    @client.post "/API/runtimeAPI/startActivity/#{activityUUID}",actAsUser,{}, opts, cb

  ###
  curl -X POST -d 'options=user:admin' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: application/xml' -H 'Authorization: Basic cmVzdHVzZXI6cmVzdGJwbQ=='  http://ec2-54-251-77-171.ap-southeast-1.compute.amazonaws.com:8080/bonita-server-rest/API/runtimeAPI/finishTask/QA_Data_Entry--1.2--16--Assign_enter_floor_data--it9f228c2a-3a3e-4889-9dca-28fc00fa1db2--mainActivityInstance--noLoop/false
  ###
  finishTask: (taskUUID,assign = false, actAsUser,opts = {},cb = ->) =>
    data = {}
    @client.post "/API/runtimeAPI/finishTask/#{taskUUID}/#{assign}",actAsUser,data, opts, cb

  ###
  curl -X POST -d 'options=user:admin' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: application/xml' -H 'Authorization: Basic cmVzdHVzZXI6cmVzdGJwbQ=='  http://ec2-54-251-77-171.ap-southeast-1.compute.amazonaws.com:8080/bonita-server-rest/API/runtimeAPI/skipTask/QA_Data_Entry--1.2--16--Assign_enter_floor_data--it9f228c2a-3a3e-4889-9dca-28fc00fa1db2--mainActivityInstance--noLoop
  ###
  skipTask: (taskUUID, actAsUser,opts = {},cb = ->) =>
    @client.post "/API/runtimeAPI/skipTask/#{taskUUID}",actAsUser,{}, opts, cb

  ###
  curl -X POST -d 'options=user:admin' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: application/xml' -H 'Authorization: Basic cmVzdHVzZXI6cmVzdGJwbQ=='  http://ec2-54-251-77-171.ap-southeast-1.compute.amazonaws.com:8080/bonita-server-rest/API/runtimeAPI/suspendTask/QA_Data_Entry--1.2--16--Assign_enter_floor_data--it9f228c2a-3a3e-4889-9dca-28fc00fa1db2--mainActivityInstance--noLoop/false
  ###
  suspendTask: (taskUUID,assign = false, actAsUser,opts = {},cb = ->) =>
    @client.post "/API/runtimeAPI/suspendTask/#{taskUUID}/#{assign}",actAsUser,{}, opts, cb

  ###
  curl -X POST -d 'options=user:admin' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: application/xml' -H 'Authorization: Basic cmVzdHVzZXI6cmVzdGJwbQ=='  http://ec2-54-251-77-171.ap-southeast-1.compute.amazonaws.com:8080/bonita-server-rest/API/runtimeAPI/resumeTask/QA_Data_Entry--1.2--16--Assign_enter_floor_data--it9f228c2a-3a3e-4889-9dca-28fc00fa1db2--mainActivityInstance--noLoop/false
  ###
  resumeTask: (taskUUID,assign = false, actAsUser,opts = {},cb = ->) =>
    @client.post "/API/runtimeAPI/resumeTask/#{taskUUID}/#{assign}",actAsUser,{}, opts, cb

  ###
  curl -X POST -d 'options=user:admin' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: application/xml' -H 'Authorization: Basic cmVzdHVzZXI6cmVzdGJwbQ=='  http://ec2-54-251-77-171.ap-southeast-1.compute.amazonaws.com:8080/bonita-server-rest/API/runtimeAPI/unassignTask/QA_Data_Entry--1.2--16--Assign_enter_floor_data--it9f228c2a-3a3e-4889-9dca-28fc00fa1db2--mainActivityInstance--noLoop
  ###
  unassignTask: (taskUUID, actAsUser,opts = {},cb = ->) =>
    @client.post "/API/runtimeAPI/unassignTask/#{taskUUID}",actAsUser,{}, opts, cb

  ###
  curl -X POST -d 'options=user:jack' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: application/xml' -H 'Authorization: Basic cmVzdHVzZXI6cmVzdGJwbQ=='  http://ec2-54-251-77-171.ap-southeast-1.compute.amazonaws.com:8080/bonita-server-rest/API/runtimeAPI/instantiateProcess/QA_Data_Entry--1.51
  result
      <ProcessInstanceUUID>
        <value>QA_Data_Entry--1.51--8</value>
      </ProcessInstanceUUID>
  ###
  instantiateProcess: (processUUID, actAsUser,opts = {},cb = ->) =>
    @client.post "/API/runtimeAPI/instantiateProcess/#{processUUID}",actAsUser,{}, opts, cb

  ###
  ###
  setVariable: (activityUUID,variableId,variableValue, actAsUser,opts = {},cb = ->) =>
    data = {}
    data[variableId] = variableValue

    @client.post "/API/runtimeAPI/setVariable/#{activityUUID}",actAsUser,data, opts, cb

  ###
  ###
  setProcessInstanceVariable: (processInstanceUUID,variableId,variableValue, actAsUser,opts = {},cb = ->) =>
    data = {}
    data[variableId] = variableValue

    @client.post "/API/runtimeAPI/setProcessInstanceVariable/#{processInstanceUUID}",actAsUser,data, opts, cb


