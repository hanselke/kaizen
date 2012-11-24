###
# Load modules
###
_ = require 'underscore'
path = require 'path'
winston = require 'winston'
config = require 'nconf'
express = require 'express'
color = require 'colors'
passport = require 'passport'
voila = require 'voila'
expressMessages = require 'express-messages-bootstrap'
trace = require './util/trace'
passportSetup = require './site/passport-setup'
routeActive = require 'route-active'

###
# Setup version
###
require('pkginfo')(module, 'version')

###
# Configure environment
###
env = process.env.NODE_ENV or 'development'

###
# Load config
###
config.file file: path.join(__dirname, '../config/env', env + '.json')

###
# Setup airbrake if present
###
airbrake = require('airbrake').createClient config.get('services:airbrake') if config.get('services:airbrake')

process.addListener 'uncaughtException', (err, stack) ->
  winston.error "Caught exception: #{err}\n#{err.stack}"
  airbrake?.notify err, () ->

# Now we start with the normal setup flow
errorHandling = require './site/error-handling'

stylus = require 'stylus'
flash = require 'connect-flash'

errors = require 'some-errors'


#RoutesRoot = require './routes/routes-root'

PassportBearerStrategy = require('passport-http-bearer').Strategy
PassportLocalStrategy = require('passport-local').Strategy


#trace = (msg = "") ->
#  winston.info msg

cookieDumper = (req, res, next) ->
  console.log "DUMPING SESSION"
  for k, v of req.session
    console.log "KEY: #{k} VALUE: #{JSON.stringify(v)}"
  console.log "END DUMPING SESSION"
  next()


fullyQualifiedUrl = (url = null) ->
  baseUrl = config.get('site:url')
  url = url.substr(1) if url && url[0] is '/'
  if url then "#{baseUrl}/#{url}" else baseUrl

expressFormsFix = () ->
  fn = (req,res,next) ->
    res.local = (key,val) ->
      res.locals[key] = val
    next()
  fn


checkNeedsInit = () ->
  fn = (req,res,next) ->
    if req.user && req.user.needsInit && !routeActive.withRegex(req, /^\/users\/complete-sign-up\/?$/i)
      res.redirect '/users/complete-sign-up'
      return
    next()
  fn

###
Helper that invokes a function in case the user has not been set up yet. It does ignore errors in the setup function to avoid nasty infinite loops.
###
checkUserNeedsSetup = (setupNewUserFn,removeRoleFn) ->
  fn = (req,res,next) ->
    if setupNewUserFn && removeRoleFn && req.user && _.find(req.user.roles || [], (x) -> x is 'user-needs-setup')
      setupNewUserFn req.user.id, (err,result) =>
        if err
          req.flash 'error', "Please refresh this page in a couple of seconds."
        removeRoleFn req.user.id,'user-needs-setup', (err) =>
          next()
    else
      next()
  fn

# Cookie based redirector, useful for startup pages
# Todo: The section with "when" redirects based on site-action
checkPerformSiteAction = ->
  fn = (req,res,next) ->
    if req.user
      cookie = req.cookies['site-action']
      res.cookie 'site-action',null,{ maxAge: 0, httpOnly: true } # Delete the cookie

      switch cookie
        when 'landing-target-page'
          if !routeActive.withRegex(req, /^\/account\/target-page\/?$/i)
            res.redirect '/account/target-page'
            return
        else
          winston.log "Received unhandled action cookie: #{cookie}"
    next()
  fn

module.exports = class App

  ###
  Starts the express server.
  @param {Integer} port the port to listen to. If null then the app does not listen
  @param {} cb an optional callback that is invoked when start is completed, after listen
  ###
  start: (port = null, cb = null) =>
    ###
    #
    # W A R N I N G
    #
    # The ordering here is of vital importance. DO NOT CHANGE ANYTHING. JUST DONT. WE HATE YOU IF YOU DO.
    # Again, changing the ordering of stuff here will in all likelyhood result in a broken system.
    #
    ###
    @app  = express()
    # Connect to database here
    # register backend data store for identity here
    # register other data store here

    @baseUrl = baseUrl = config.get('site:url')

    # Ensures that we use only one local url for passport so that it does not loose cokies
    @app.use (req, res, next) =>
      if port && req.headers.host is '127.0.0.1:#{port}'
        res.writeHead 303, 'Location': "http://localhost:#{port}#{req.url}" 
        res.end()
      else
        next()

    @app.use express.favicon(__dirname + '/../public/favicon.ico', config.get('cache'))
    @app.use express.static(__dirname + '/../public', config.get('cache'))
    @app.use express.logger()
    @app.use express.responseTime()
    @app.use expressFormsFix()
    
    @app.use express.cookieParser config.get('site:secret')
    @app.use express.cookieSession 
      cookie: 
        maxAge: 31536000000

    @app.use flash()
    @app.use express.bodyParser()
    @app.use express.methodOverride()

    # CSRF
    # @app.use(route, express.csrf()) for route in  ["/developers","account"] #, "/users"
  

    @app.use passport.initialize()
    @app.use passport.session()
    # @app.use cookieDumper
 
    @app.locals 
      config : config
      packageVersion : exports.version
      '_' : _
      fullyQualifiedUrl : fullyQualifiedUrl
      apiDocs : require './modules/api-docs'


    @app.use (req, res,next) =>
      res.locals.messages = expressMessages
      res.locals.currentUser = req.user || null
      #trace "CURRENT USER: #{JSON.stringify(req.user)} "
      res.locals.csrf = if req.session && req.session._csrf then req.session._csrf else ""

      # TODO: Add the following to the config files
      res.locals.title = config.get('site:subTitle')
      res.locals.keywords = config.get('site:keywords')
      res.locals.author = config.get('site:author')
      res.locals.description = config.get('site:description')
      res.locals.ogTitle = res.locals.title
      res.locals.ogImage = config.get("openGraph:image")
      res.locals.ogDescription = config.get('openGraph:description')
      res.locals.ogType = "website"
      res.locals.ogUrl =  config.get('openGraph:url')
      res.locals.infoFlash = () -> req.flash('info') || []
      res.locals.warningFlash = () -> req.flash('warning') || []
      res.locals.errorFlash = () -> req.flash('error') || []
      res.locals.isInRole = (role) -> req.user && req.user.roles && !!_.find(req.user.roles,(x)-> x is role)
      next()


    settings = 
      app: @app
      passport : passport
      baseUrl : @baseUrl

    # TODO: Order might be important, and we need to check that.
    @routes =
      root : new RoutesRoot settings
      
    @app.set('views', __dirname + '/../views')
    @app.set('view engine', 'jade')

    @app.use '/assets', voila(__dirname + '/../', config.get('voila'))
    @app.use checkNeedsInit()
    @app.use checkUserNeedsSetup(@appApiClient?.actions?.setupNewUser,@identityServiceClient?.users?.deleteRoles )
    @app.use checkPerformSiteAction()

    route.setupLocals() for key,route of @routes

    passportSetup(@app,@identityServiceClient,config,baseUrl)


    route.setupRoutes() for key,route of @routes


    @app.use @app.router
    errorHandling(@app, config.get('stacktrace'), airbrake)

    if port
      @server = @app.listen port
      winston.info "Express server listening on port #{port} in #{@app.settings.env} mode".cyan

    cb null, @ if cb

  stop: (cb = null) =>
    @server.close() if @server
    cb null, @ if cb
