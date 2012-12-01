###
Handles the identity API in bonita
###
module.exports = class Identity
  constructor:(@client) ->
    throw new Error "client parameter is required" unless @client

  ###
  curl -X POST -d 'options=user:admin' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: application/xml' -H 'Authorization: Basic cmVzdHVzZXI6cmVzdGJwbQ=='  http://ec2-54-251-77-171.ap-southeast-1.compute.amazonaws.com:8080/bonita-server-rest/API/identityAPI/getAllUsers

  
  ###
  getAllUsers: (actAsUser,opts = {},cb = ->) =>
    @client.post "/API/identityAPI/getAllUsers",actAsUser,{}, opts, cb

  ###
  curl -X POST -d 'options=user:admin&username=martin&password=1234' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: application/xml' -H 'Authorization: Basic cmVzdHVzZXI6cmVzdGJwbQ=='  http://ec2-54-251-77-171.ap-southeast-1.compute.amazonaws.com:8080/bonita-server-rest/API/identityAPI/addUser
  RETURNS:
  <User>
    <dbid>624</dbid>
    <uuid>56ad8150-20af-40dd-934f-6169fca5e7e3</uuid>
    <password>7110eda4d09e62aa5e4a390b0a572acd2c220</password>
    <username>martin</username>
  </User>
  ###
  addUser: (username,password,actAsUser,opts = {},cb = ->) =>
    @client.post "/API/identityAPI/addUser",actAsUser,{username : username, password : password}, {}, cb

  ###
  curl -X POST -d 'options=user:admin' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Accept: application/xml' -H 'Authorization: Basic cmVzdHVzZXI6cmVzdGJwbQ=='  http://ec2-54-251-77-171.ap-southeast-1.compute.amazonaws.com:8080/bonita-server-rest/API/identityAPI/addRoleToUser/admin/martin
  ###
  addRoleToUser: (username,role,actAsUser,opts = {},cb = ->) =>
    @client.post "/API/identityAPI/addRoleToUser/#{role}/#{username}",actAsUser,{}, {}, cb

  removeUser: (username,actAsUser,opts = {},cb = ->) =>
    @client.post "/API/identityAPI/removeUser/#{username}",actAsUser,{}, {}, cb
