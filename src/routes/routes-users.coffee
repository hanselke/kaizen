
_ = require 'underscore'
form = require "express-form"
routeActive = require 'route-active'
#protectResource = require '../protect-resource'
RoutesUsersPathHelper = require './routes-users-path-helper'

class FormDataSignIn
  constructor: (@username = '', @password = '') ->

validateSignIn = form(
      form.filter("username").trim(),
      form.validate("username", "User Name or Email").required(),
      form.filter("password").trim(),
      form.validate("password", "Password").required()
    )

module.exports = class RoutesUsers

  constructor:(settings) ->
    _.extend @,settings
    throw new Error("app parameter is required") unless @app
    throw new Error("passport parameter is required") unless @passport
    throw new Error("identityStore parameter is required") unless @identityStore

  setupLocals: () =>
    @app.locals.routesUsers = @routesUsersPathHelper = new RoutesUsersPathHelper

    #@app.use (req, res,next) =>
    #  res.locals.routesUsersActive = () -> routeActive.withRegex(req, /^\/users\/?/i)
    #  res.locals.routesUsersSignInActive = () -> routeActive.withRegex(req, /^\/users\/sign-in\/?$/i)
    #  res.locals.routesUsersResetPasswordActive = () -> routeActive.withRegex(req, /^\/users\/reset-password\/?$/i)
    #  res.locals.routesUsersChangePasswordActive = () -> routeActive.withRegex(req, /^\/users\/change-password\/?$/i)
    #  next()

  setupRoutes: () =>
    @app.get '/users/sign-in', @signIn
    @app.post '/users/sign-in', validateSignIn, @passport.authenticate("local", failureRedirect: "/users/sign-in?error=1"),  @signInPost

    @app.get '/users/sign-out', @signOutGet

  _nextRedirect:(req, res) =>
    res.redirect req.body.next || req.query.next || "/"

  signIn: (req, res) =>
    res.render 'users/sign-in',
      _.extend new FormDataSignIn(),
        next : req.query.next
        layout: false
        title: "Sign In"
        controllerName : 'users'
        bodyCss : 'userdialog_area has_header_menu'

  signInPost: (req, res) =>
    @_nextRedirect req, res

  ###
  Sign Out - This is a get for convenience only.
  ###
  signOutGet: (req, res) =>
    req.logOut()
    @_nextRedirect req, res
