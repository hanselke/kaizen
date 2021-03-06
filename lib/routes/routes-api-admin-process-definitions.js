// Generated by CoffeeScript 1.4.0
(function() {
  var RoutesApiAdminProcessDefinitions, async, errors, fs, winston, xlsxToForm, _,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  _ = require('underscore');

  async = require('async');

  winston = require('winston');

  errors = require('some-errors');

  fs = require('fs');

  xlsxToForm = require('../modules/xlsx-to-form');

  module.exports = RoutesApiAdminProcessDefinitions = (function() {

    function RoutesApiAdminProcessDefinitions(settings) {
      this.uploadAdminProcessDefinitionLayout = __bind(this.uploadAdminProcessDefinitionLayout, this);

      this.getAdminProcessDefinitionLayout = __bind(this.getAdminProcessDefinitionLayout, this);

      this.uploadAdminProcessDefinitionExcel = __bind(this.uploadAdminProcessDefinitionExcel, this);

      this.getAdminProcessDefinition = __bind(this.getAdminProcessDefinition, this);

      this.patchAdminProcessDefinition = __bind(this.patchAdminProcessDefinition, this);

      this.deleteAdminProcessDefinition = __bind(this.deleteAdminProcessDefinition, this);

      this.postAdminProcessDefinitions = __bind(this.postAdminProcessDefinitions, this);

      this.getAdminProcessDefinitions = __bind(this.getAdminProcessDefinitions, this);

      this.setupRoutes = __bind(this.setupRoutes, this);

      this.setupLocals = __bind(this.setupLocals, this);
      _.extend(this, settings);
      if (!this.app) {
        throw new Error("app parameter is required");
      }
    }

    RoutesApiAdminProcessDefinitions.prototype.setupLocals = function() {};

    RoutesApiAdminProcessDefinitions.prototype.setupRoutes = function() {
      this.app.get('/api/admin/process-definitions', this.getAdminProcessDefinitions);
      this.app.post('/api/admin/process-definitions', this.postAdminProcessDefinitions);
      this.app["delete"]('/api/admin/process-definitions/:processDefinitionId', this.deleteAdminProcessDefinition);
      this.app.patch('/api/admin/process-definitions/:processDefinitionId', this.patchAdminProcessDefinition);
      this.app.put('/api/admin/process-definitions/:processDefinitionId', this.patchAdminProcessDefinition);
      this.app.get('/api/admin/process-definitions/:processDefinitionId', this.getAdminProcessDefinition);
      this.app.post('/api/admin/process-definitions/:processDefinitionId/excel', this.uploadAdminProcessDefinitionExcel);
      this.app.get('/api/admin/process-definitions/:processDefinitionId/layout', this.getAdminProcessDefinitionLayout);
      return this.app.post('/api/admin/process-definitions/:processDefinitionId/layout', this.uploadAdminProcessDefinitionLayout);
    };

    RoutesApiAdminProcessDefinitions.prototype.getAdminProcessDefinitions = function(req, res, next) {
      var _this = this;
      if (!req.user) {
        return res.json(401, {});
      }
      return this.dbStore.processDefinitions.all({
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

    RoutesApiAdminProcessDefinitions.prototype.postAdminProcessDefinitions = function(req, res, next) {
      var _this = this;
      return this.dbStore.processDefinitions.create(req.body, {
        actorId: req.user._id
      }, function(err, item) {
        return res.json(item);
      });
    };

    RoutesApiAdminProcessDefinitions.prototype.deleteAdminProcessDefinition = function(req, res, next) {
      var processDefinitionId,
        _this = this;
      processDefinitionId = req.params.processDefinitionId;
      return this.dbStore.processDefinitions.destroy(processDefinitionId, null, true, function(err, item) {
        if (err) {
          return next(err);
        }
        return res.json({});
      });
    };

    RoutesApiAdminProcessDefinitions.prototype.patchAdminProcessDefinition = function(req, res, next) {
      var isValidStateMachine, json, processDefinitionId,
        _this = this;
      console.log(JSON.stringify(req.body));
      processDefinitionId = req.params.processDefinitionId;
      isValidStateMachine = true;
      if (req.body.stateMachine) {
        try {
          json = JSON.parse(req.body.stateMachine);
        } catch (e) {
          isValidStateMachine = false;
        }
      }
      if ((req.body.taskNamePrefix || '').length > 8) {
        return res.json(422, {
          message: "The task name prefix must be 8 chars or less."
        });
      }
      if (!isValidStateMachine) {
        return res.json(422, {
          message: "State Machine is not valid. Please use jsonformatter.curiousconcept.com to validate"
        });
      }
      return this.dbStore.processDefinitions.patch(processDefinitionId, req.body, {}, function(err, item) {
        if (err) {
          return next(err);
        }
        return res.json(item);
      });
    };

    RoutesApiAdminProcessDefinitions.prototype.getAdminProcessDefinition = function(req, res, next) {
      var processDefinitionId,
        _this = this;
      processDefinitionId = req.params.processDefinitionId;
      return this.dbStore.processDefinitions.get(processDefinitionId, null, true, function(err, item) {
        var hasLayout, hasSource;
        if (err) {
          return next(err);
        }
        hasSource = item.sourceXlsx && item.sourceXlsx.length > 0;
        hasLayout = item.layout && _.keys(item.layout).length > 0;
        delete item.sourceXlsx;
        delete item.layout;
        item = item.toJSON();
        item.hasSource = hasSource;
        item.hasLayout = hasLayout;
        return res.json(item);
      });
    };

    RoutesApiAdminProcessDefinitions.prototype.uploadAdminProcessDefinitionExcel = function(req, res, next) {
      var file, processDefinitionId,
        _this = this;
      processDefinitionId = req.params.processDefinitionId;
      file = req.files.file;
      if (!file) {
        return next(new Error("No file present"));
      }
      if (!processDefinitionId) {
        return next(new Error("No processDefinitionId"));
      }
      return fs.readFile(file.path, 'utf8', function(err, content) {
        var base64Content;
        if (err) {
          return next(err);
        }
        base64Content = new Buffer(content).toString('base64');
        return _this.dbStore.processDefinitions.saveExcel(processDefinitionId, base64Content, file.size, file.name, file.type, function(err, item) {
          if (err) {
            return next(err);
          }
          return res.json({});
        });
      });
    };

    RoutesApiAdminProcessDefinitions.prototype.getAdminProcessDefinitionLayout = function(req, res, next) {
      var processDefinitionId,
        _this = this;
      processDefinitionId = req.params.processDefinitionId;
      return this.dbStore.processDefinitions.get(processDefinitionId, null, true, function(err, item) {
        if (err) {
          return next(err);
        }
        res.setHeader('Content-Disposition', 'Attachment');
        return res.json(item.layout);
      });
    };

    RoutesApiAdminProcessDefinitions.prototype.uploadAdminProcessDefinitionLayout = function(req, res, next) {
      var file, processDefinitionId,
        _this = this;
      processDefinitionId = req.params.processDefinitionId;
      file = req.files.file;
      if (!file) {
        return next(new Error("No file present"));
      }
      if (!processDefinitionId) {
        return next(new Error("No processDefinitionId"));
      }
      return fs.readFile(file.path, 'utf8', function(err, content) {
        var parsedJson;
        if (err) {
          return next(err);
        }
        parsedJson = null;
        try {
          parsedJson = JSON.parse(content);
        } catch (e) {
          if (!parsedJson) {
            return next(new Error('Invalid JSON'));
          }
        }
        return xlsxToForm.loadVbaOutput(parsedJson, function(err, converted) {
          if (err) {
            return next(err);
          }
          return _this.dbStore.processDefinitions.saveLayout(processDefinitionId, converted, function(err, item) {
            if (err) {
              return next(err);
            }
            return res.json({});
          });
        });
      });
    };

    return RoutesApiAdminProcessDefinitions;

  })();

}).call(this);
