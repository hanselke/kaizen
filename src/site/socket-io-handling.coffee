socketIo = require 'socket.io'

io = null # IMPORTANT

module.exports = (server) ->
  io = socketIo.listen(server)
  io.set "log level", 0
  lines = []
  io.sockets.on "connection", (socket) ->
    socket.on "msg", (data) ->
      lines.push data
      lines.splice 0, lines.length - 100  if lines.length > 100
      socket.broadcast.emit "msg", data

    socket.on "nick", (data) ->
      oldNick = socket.get("nick", ->
        socket.set "nick", data.nick, ->

      )

    
    #       if (!oldNick) {
    #         var d = { time: new Date(), msg: data.nick+' joined to the chat!' }
    #         lines.push(d)
    #         socket.emit('msg', d)
    #         socket.broadcast.emit('msg', d)
    #       } else if (oldNick != data.nick) {
    #         var d = { time: new Date(), msg: oldNick+' is now known as '+data.nick }
    #         lines.push(d)
    #         socket.emit('msg', d)
    #         socket.broadcast.emit('msg', d)
    #       }
    socket.on "lines", (data) ->
      socket.emit "lines",
        lines: lines


