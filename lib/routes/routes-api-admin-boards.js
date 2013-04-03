// Generated by CoffeeScript 1.4.0
(function() {
  var RoutesApiBoards, async, errors, fs, stateMachinePackage, winston, xlsxToForm, _,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  _ = require('underscore');

  async = require('async');

  winston = require('winston');

  errors = require('some-errors');

  fs = require('fs');

  xlsxToForm = require('../modules/xlsx-to-form');

  stateMachinePackage = require('../modules/state-machine');

  module.exports = RoutesApiBoards = (function() {

    function RoutesApiBoards(settings) {
      this.getAdminBoard = __bind(this.getAdminBoard, this);

      this.patchAdminBoard = __bind(this.patchAdminBoard, this);

      this.deleteAdminBoard = __bind(this.deleteAdminBoard, this);

      this.postAdminBoards = __bind(this.postAdminBoards, this);

      this.getAdminBoards = __bind(this.getAdminBoards, this);

      this.setupRoutes = __bind(this.setupRoutes, this);

      this.setupLocals = __bind(this.setupLocals, this);
      _.extend(this, settings);
      if (!this.app) {
        throw new Error("app parameter is required");
      }
    }

    RoutesApiBoards.prototype.setupLocals = function() {};

    RoutesApiBoards.prototype.setupRoutes = function() {
      this.app.get('/api/admin/boards', this.getAdminBoards);
      this.app.post('/api/admin/boards', this.postAdminBoards);
      this.app["delete"]('/api/admin/boards/:boardId', this.deleteAdminBoard);
      this.app.patch('/api/admin/boards/:boardId', this.patchAdminBoard);
      this.app.put('/api/admin/boards/:boardId', this.patchAdminBoard);
      return this.app.get('/api/admin/boards/:boardId', this.getAdminBoard);
    };

    RoutesApiBoards.prototype.getAdminBoards = function(req, res, next) {
      var _this = this;
      if (!req.user) {
        return res.json(401, {});
      }
      return this.dbStore.boards.all({
        actor: null,
        offset: 0,
        count: 200
      }, function(err, result) {
        if (err) {
          return next(err);
        }
        return res.json(result);
      });
    };

    RoutesApiBoards.prototype.postAdminBoards = function(req, res, next) {
      var _this = this;
      return this.dbStore.boards.create(req.body, {
        actorId: req.user._id
      }, function(err, item) {
        return res.json(item);
      });
    };

    RoutesApiBoards.prototype.deleteAdminBoard = function(req, res, next) {
      var boardId,
        _this = this;
      boardId = req.params.boardId;
      return this.dbStore.boards.destroy(boardId, {}, function(err, item) {
        if (err) {
          return next(err);
        }
        return res.json({});
      });
    };

    RoutesApiBoards.prototype.patchAdminBoard = function(req, res, next) {
      var boardId, isValidStateMachine,
        _this = this;
      boardId = req.params.boardId;
      isValidStateMachine = true;
      /*
          if req.body.stateMachine
            try
              json = JSON.parse(req.body.stateMachine)
            catch e
              isValidStateMachine = false
      
          if (req.body.taskNamePrefix || '').length > 8
            return res.json 422,{message: "The task name prefix must be 8 chars or less."}
          
          if !isValidStateMachine
            return res.json 422,{message: "State Machine is not valid. Please use jsonformatter.curiousconcept.com to validate"}
      */

      return this.dbStore.boards.patch(boardId, req.body, {}, function(err, item) {
        if (err) {
          return next(err);
        }
        return res.json(item);
      });
    };

    RoutesApiBoards.prototype.getAdminBoard = function(req, res, next) {
      var boardId,
        _this = this;
      boardId = req.params.boardId;
      return this.dbStore.boards.get(boardId, {}, function(err, item) {
        if (err) {
          return next(err);
        }
        return res.json(item);
      });
    };

    return RoutesApiBoards;

  })();

}).call(this);