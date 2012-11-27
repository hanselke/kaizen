###
Handles the identity API in bonita
###
module.exports = class QueryRuntime
  constructor:(@client) ->
    throw new Error "client parameter is required" unless @client

  getProcessInstances: (processUUID, actAsUser,opts = {},cb = ->) =>
    @client.post "/API/queryRuntimeAPI/getProcessInstances/#{processUUID}",actAsUser,{}, opts, cb


  ###
  curl -X POST -d 'options=user:admin' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: application/xml' -H 'Authorization: Basic cmVzdHVzZXI6cmVzdGJwbQ=='  http://ec2-54-251-77-171.ap-southeast-1.compute.amazonaws.com:8080/bonita-server-rest/API/queryRuntimeAPI/getTaskList/QA_Data_Entry--1.2--16/READY
  ###
  getTaskList: (instanceUUID,taskState, actAsUser,opts = {},cb = ->) =>
    @client.post "/API/queryRuntimeAPI/getTaskList/#{instanceUUID}/#{taskState}",actAsUser,{}, opts, cb

  ###
  curl -X POST -d 'options=user:admin' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: application/xml' -H 'Authorization: Basic cmVzdHVzZXI6cmVzdGJwbQ=='  http://ec2-54-251-77-171.ap-southeast-1.compute.amazonaws.com:8080/bonita-server-rest/API/queryRuntimeAPI/getTasks/QA_Data_Entry--1.2--16
  ###
  getTasks: (instanceUUID, actAsUser,opts = {},cb = ->) =>
    @client.post "/API/queryRuntimeAPI/getTasks/#{instanceUUID}",actAsUser,{}, opts, cb


