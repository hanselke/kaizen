// Generated by CoffeeScript 1.4.0
(function() {
  var ObjectId, RoutesApi, async, errors, fs, mongoose, stateMachineForProcessDefinition, stateMachinePackage, winston, xlsxToForm, _,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  _ = require('underscore');

  async = require('async');

  winston = require('winston');

  errors = require('some-errors');

  fs = require('fs');

  xlsxToForm = require('../modules/xlsx-to-form');

  stateMachinePackage = require('openb-app-state-machine');

  mongoose = require("mongoose");

  ObjectId = mongoose.Types.ObjectId;

  stateMachineForProcessDefinition = require('./helpers/state-machine-for-process-definition');

  module.exports = RoutesApi = (function() {

    function RoutesApi(settings) {
      this.getProcessDefinitionHtml = __bind(this.getProcessDefinitionHtml, this);

      this.getProcessDefinitionCss = __bind(this.getProcessDefinitionCss, this);

      this.validateProcessDefinition = __bind(this.validateProcessDefinition, this);

      this.setupRoutes = __bind(this.setupRoutes, this);

      this.setupLocals = __bind(this.setupLocals, this);
      _.extend(this, settings);
      if (!this.app) {
        throw new Error("app parameter is required");
      }
      if (!this.identityStore) {
        throw new Error("identityStore parameter is required");
      }
    }

    RoutesApi.prototype.setupLocals = function() {};

    RoutesApi.prototype.setupRoutes = function() {
      this.app.get('/api/process-definitions/:processDefinitionId/validate', this.validateProcessDefinition);
      this.app.get('/api/process-definitions/:processDefinitionId/form-css', this.getProcessDefinitionCss);
      return this.app.get('/api/process-definitions/:processDefinitionId/:taskId/form-html', this.getProcessDefinitionHtml);
    };

    RoutesApi.prototype.validateProcessDefinition = function(req, res, next) {
      var processDefinitionId,
        _this = this;
      processDefinitionId = req.params.processDefinitionId;
      return this.dbStore.processDefinitions.get(processDefinitionId, null, true, function(err, item) {
        if (err) {
          return next(err);
        }
        return stateMachineForProcessDefinition(item, function(err, sm) {
          var result;
          if (err) {
            return next(err);
          }
          result = {
            processDefinition: {
              _id: item.id,
              name: item.name
            }
          };
          return res.json(result);
        });
      });
    };

    /*
      http://localhost:8001/api/process-definitions/5101f5620cb4645c7800000b/form-css
    */


    RoutesApi.prototype.getProcessDefinitionCss = function(req, res, next) {
      var processDefinitionId,
        _this = this;
      processDefinitionId = req.params.processDefinitionId;
      return this.dbStore.processDefinitions.get(processDefinitionId, null, true, function(err, item) {
        if (err) {
          return next(err);
        }
        if (!(item && xlsxToForm.isValidLayout(item.layout))) {
          res.send("p.warning-box {margin-top:50px;background-color:red;color:white;}");
          return;
        }
        return xlsxToForm.createCssFromLayoutForm(item.layout, function(err, css) {
          if (err) {
            return done(err);
          }
          res.setHeader('Content-Type', 'text/css');
          return res.send(css);
        });
      });
    };

    /*
      http://localhost:8001/api/process-definitions/50d22f260b75ca1d9000000c/taskIdhere/form-html
    */


    RoutesApi.prototype.getProcessDefinitionHtml = function(req, res, next) {
      var editAllStates, processDefinitionId, taskId,
        _this = this;
      editAllStates = req.query.editAllStates;
      processDefinitionId = req.params.processDefinitionId;
      taskId = req.params.taskId;
      return this.dbStore.processDefinitions.get(processDefinitionId, null, true, function(err, item) {
        if (err) {
          return next(err);
        }
        if (!(item && xlsxToForm.isValidLayout(item.layout))) {
          res.send("<p class=\"warning\">Could not read Layout Definition for process " + item.name + "</p>");
          return;
        }
        return stateMachineForProcessDefinition(item, function(err, sm) {
          if (err) {
            return next(err);
          }
          return _this.dbStore.tasks.get(taskId, {}, function(err, task) {
            var currentTaskState, options;
            if (err) {
              return next(err);
            }
            currentTaskState = sm.getExcelFieldFromState(task.state) || 'undefined';
            options = {
              editAllStates: editAllStates,
              isActiveInputCell: function(cell) {
                if (!(cell.text && cell.text.length > 0)) {
                  return false;
                }
                if (!sm.existsAsExcelField(cell.text)) {
                  return false;
                }
                return true;
              },
              isActiveInputCellCurrent: function(cell) {
                if (!(cell.text && cell.text.length > 0)) {
                  return false;
                }
                if (cell.text !== currentTaskState) {
                  return false;
                }
                return true;
              }
            };
            return xlsxToForm.createHtmlFromLayoutForm(item.layout, options, function(err, html) {
              if (err) {
                return done(err);
              }
              html = "" + html;
              return res.send(html);
            });
          });
        });
      });
    };

    /*
      _stateMachineForProcessDefinition: (processDefinition,cb) =>
        return cb new Error("No valid process defintions found.") unless processDefinition
    
        smData = null
        try
          smData = JSON.parse(processDefinition.stateMachine)
        catch e
          console.log "Could not parse statemachine for #{processDefinition.name}"
          console.log processDefinition.stateMachine
          return cb new Error("Could not parse JSON State Machine for Process Defintion #{processDefinition.name}")
    
        sm = stateMachinePackage.stateMachine()
        sm.loadFromObject smData
    
        cb null,sm
    */


    return RoutesApi;

  })();

}).call(this);
