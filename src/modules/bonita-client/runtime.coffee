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
  curl -X POST -d 'options=user:admin' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: application/xml' -H 'Authorization: Basic cmVzdHVzZXI6cmVzdGJwbQ=='  http://ec2-54-251-77-171.ap-southeast-1.compute.amazonaws.com:8080/bonita-server-rest/API/runtimeAPI/startActivity/QA_Data_Entry--1.2--16--Assign_enter_floor_data--it9f228c2a-3a3e-4889-9dca-28fc00fa1db2--mainActivityInstance--noLoop
  ###
  startActivity: (activityUUID, actAsUser,opts = {},cb = ->) =>
    @client.post "/API/runtimeAPI/startActivity/#{activityUUID}",actAsUser,{}, opts, cb
