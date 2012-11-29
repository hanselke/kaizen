// Generated by CoffeeScript 1.4.0
(function() {
  var RoutesAppPathHelper, RoutesOther, protectResource, _,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  _ = require('underscore');

  RoutesAppPathHelper = require('./routes-app-path-helper');

  protectResource = require('../site/protect-resource');

  module.exports = RoutesOther = (function() {

    function RoutesOther(settings) {
      this.getTask = __bind(this.getTask, this);

      this.getMain = __bind(this.getMain, this);

      this.getApp = __bind(this.getApp, this);

      this.setupRoutes = __bind(this.setupRoutes, this);

      this.setupLocals = __bind(this.setupLocals, this);
      _.extend(this, settings);
      if (!this.app) {
        throw new Error("app parameter is required");
      }
    }

    RoutesOther.prototype.setupLocals = function() {
      return this.app.locals.routesApps = this.routesAppPathHelper = new RoutesAppPathHelper;
    };

    RoutesOther.prototype.setupRoutes = function() {
      this.app.get('/app', protectResource(), this.getApp);
      this.app.get('/app/main', this.getMain);
      return this.app.get('/app/task', this.getTask);
    };

    RoutesOther.prototype.getApp = function(req, res, next) {
      return res.render('app/index.ejs', {
        pretty: true
      });
    };

    RoutesOther.prototype.getMain = function(req, res, next) {
      return res.render('app/main', {
        pretty: true
      });
    };

    RoutesOther.prototype.getTask = function(req, res, next) {
      return res.render('app/task', {
        pretty: true
      });
    };

    return RoutesOther;

  })();

}).call(this);