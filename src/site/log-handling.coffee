express = require 'express'
ansiColor = require('ansi-color').set

module.exports = (app) ->

  pad2 = (i) ->
    (if (i < 10) then "0" + i else i)

  express.logger.token "short-date", (req, res) ->
    d = new Date()
    pad2(d.getMonth() + 1) + "." + pad2(d.getDate()) + " " + d.toTimeString().substr(0, 8)

  express.logger.token "user", (req, res) ->
    (if req.user then req.user.username or req.user.primaryEmail else "No-user")

  express.logger.token "color-status", (req, res) ->
    s = res.statusCode
    color = "green"
    if s >= 500
      color = "red"
    else if s >= 400
      color = "yellow"
    else color = "cyan"  if s >= 300
    ansiColor s, color

  app.use express.logger(format: ansiColor("[:short-date] (:remote-addr) [:user]", "white") + " :method :url - HTTP :color-status - :response-time msec")
