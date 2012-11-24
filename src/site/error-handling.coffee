errors = require 'some-errors'
winston = require 'winston'

###
Generic error handler that takes care of the correct output.
###
module.exports = (app, showStackTrace, airbrake) ->
  throw new Error "app parameter needs to be defined" unless app

  app.use (req, res, next) ->
    # TODO: Add this to analytics

    res.format
      html: () ->
        res.status 404
        res.render "errors/404",
            layout: false
            status: 404
            title: "Page not found"
      json: () ->
        res.json 404,
          message : "Page not found"
          errors: []


  app.use (err, req, res, next) ->
    winston.error "#{err}"
    airbrake.notify(err) if airbrake

    if err instanceof errors.ClearPassportSession
      req.logOut()
      res.redirect "/"
    else if err instanceof errors.NotFound
      res.format
        html: () ->
          res.status 404
          res.render "errors/404",
              status: 404
              title: "Page not found "
        json: () ->
          res.json 404,
            message : "Page not found"
            errors: []
    else
      res.format
        html: () ->
          res.status err.status or 500
          res.render "errors/500",
              status: err.status or 500
              error: err
              showStack: showStackTrace
              title: "Something went wrong!"
        json: () ->
          res.json err.status or 500,
            message :  err.message or "Internal Server Error"
            errors: []

