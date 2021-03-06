// Generated by CoffeeScript 1.4.0
(function() {
  var ObjectId, RoutesApi, async, errors, fs, mongoose, rolesForStateAndProcessDefinition, stateMachineForProcessDefinition, stateMachinePackage, winston, xlsxToForm, _,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  _ = require('underscore');

  async = require('async');

  winston = require('winston');

  errors = require('some-errors');

  fs = require('fs');

  xlsxToForm = require('../modules/xlsx-to-form');

  stateMachinePackage = require('openb-app-state-machine');

  stateMachineForProcessDefinition = require('./helpers/state-machine-for-process-definition');

  rolesForStateAndProcessDefinition = require('./helpers/roles-for-state-and-process-definition');

  mongoose = require("mongoose");

  ObjectId = mongoose.Types.ObjectId;

  module.exports = RoutesApi = (function() {

    function RoutesApi(settings) {
      this.getBoard2 = __bind(this.getBoard2, this);

      this._addUsernameToTasks = __bind(this._addUsernameToTasks, this);

      this._addAllowedRolesForStateTransition = __bind(this._addAllowedRolesForStateTransition, this);

      this._getActiveProcessDefinitionId = __bind(this._getActiveProcessDefinitionId, this);

      this._stateMachineForAny = __bind(this._stateMachineForAny, this);

      this._stateMachineForProcessDefinitionId = __bind(this._stateMachineForProcessDefinitionId, this);

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
      return this.app.get('/api/board', this.getBoard2);
    };

    RoutesApi.prototype._stateMachineForProcessDefinitionId = function(processDefinitionId, cb) {
      var _this = this;
      return this.dbStore.processDefinitions.get(processDefinitionId, null, true, function(err, item) {
        if (err) {
          return next(err);
        }
        return stateMachineForProcessDefinition(item, function(err, sm) {
          return cb(err, sm);
        });
      });
      /*
          @dbStore.processDefinitions.get2 processDefinitionId,{select: '_id stateMachine name'}, (err,processDefinition) =>
            return cb err if err
            return cb new Error("Process Definition #{processDefinitionId} not found.") unless processDefinition
      
            if !processDefinition.stateMachine || processDefinition.stateMachine.trim().length is 0
              return cb new Error("Missing state machine for process definition #{processDefinitionId}")
      
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

    };

    RoutesApi.prototype._stateMachineForAny = function(cb) {
      var _this = this;
      return this.dbStore.processDefinitions.getValidProcessDefinition({
        select: '_id stateMachine name'
      }, function(err, processDefinition) {
        var sm, smData;
        if (err) {
          return cb(err);
        }
        if (!processDefinition) {
          return cb(new Error("No valid process defintions found."));
        }
        smData = null;
        try {
          smData = JSON.parse(processDefinition.stateMachine);
        } catch (e) {
          console.log("Could not parse statemachine for " + processDefinition.name);
          console.log(processDefinition.stateMachine);
          return cb(new Error("Could not parse JSON State Machine for Process Defintion " + processDefinition.name));
        }
        sm = stateMachinePackage.stateMachine();
        sm.loadFromObject(smData);
        return cb(null, sm);
      });
    };

    RoutesApi.prototype._getActiveProcessDefinitionId = function(next) {
      var _this = this;
      return this.dbStore.processDefinitions.firstProcessDefinition({
        select: '_id'
      }, function(err, processDefinition) {
        if (err) {
          return next(err);
        }
        if (!processDefinition) {
          return next(new Error("Process definition not found"));
        }
        return next(null, processDefinition._id);
      });
    };

    /*
      This gathers the allowed role for the current state all the tasks are in.
      This works by first retrieving all the state machines, then querying it.
    */


    RoutesApi.prototype._addAllowedRolesForStateTransition = function(lanes, cb) {
      var card, lane, statesAndProcessDefinitionIds, _i, _j, _len, _len1, _ref,
        _this = this;
      statesAndProcessDefinitionIds = [];
      for (_i = 0, _len = lanes.length; _i < _len; _i++) {
        lane = lanes[_i];
        _ref = lane.cards;
        for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
          card = _ref[_j];
          if (card.nextState && card.nextState.length > 0) {
            statesAndProcessDefinitionIds.push({
              processDefinitionId: card.processDefinitionId,
              state: card.nextState
            });
          }
        }
      }
      return rolesForStateAndProcessDefinition(statesAndProcessDefinitionIds, this.dbStore, function(err, processDefinitonToStateMap) {
        var states, _k, _l, _len2, _len3, _ref1;
        for (_k = 0, _len2 = lanes.length; _k < _len2; _k++) {
          lane = lanes[_k];
          _ref1 = lane.cards;
          for (_l = 0, _len3 = _ref1.length; _l < _len3; _l++) {
            card = _ref1[_l];
            if (!(card.nextState && card.nextState.length > 0)) {
              continue;
            }
            states = processDefinitonToStateMap[card.processDefinitionId.toString()];
            if (states) {
              card.allowedRolesForStateTransition = states[card.nextState] || [];
            }
          }
        }
        return cb(null);
      });
    };

    RoutesApi.prototype._addUsernameToTasks = function(lanes, cb) {
      var card, idList, lane, unresolvedUserIds, _i, _j, _len, _len1, _ref,
        _this = this;
      if (!this.usernameMap) {
        this.usernameMap = {};
      }
      if (!this.rolesMap) {
        this.rolesMap = {};
      }
      unresolvedUserIds = {};
      for (_i = 0, _len = lanes.length; _i < _len; _i++) {
        lane = lanes[_i];
        _ref = lane.cards;
        for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
          card = _ref[_j];
          if (card.userId) {
            card.username = this.usernameMap[card.userId];
            card.roles = this.rolesMap[card.userId] || [];
            if (!this.usernameMap[card.userId]) {
              unresolvedUserIds[card.userId] = true;
            }
          }
        }
      }
      if (_.keys(unresolvedUserIds).length === 0) {
        return cb(null);
      } else {
        idList = _.map(_.keys(unresolvedUserIds), function(x) {
          return new ObjectId(x.toString());
        });
        return this.identityStore.models.User.find({}).where('_id')["in"](idList).select('_id username roles').exec(function(err, items) {
          var item, _k, _l, _len2, _len3, _len4, _m, _ref1;
          if (err) {
            return cb(err);
          }
          items || (items = []);
          for (_k = 0, _len2 = items.length; _k < _len2; _k++) {
            item = items[_k];
            _this.usernameMap[item._id.toString()] = item.username;
            _this.rolesMap[item._id.toString()] = item.roles || [];
          }
          for (_l = 0, _len3 = lanes.length; _l < _len3; _l++) {
            lane = lanes[_l];
            _ref1 = lane.cards;
            for (_m = 0, _len4 = _ref1.length; _m < _len4; _m++) {
              card = _ref1[_m];
              if (card.userId) {
                card.username = _this.usernameMap[card.userId];
              }
              if (card.userId) {
                card.roles = _this.rolesMap[card.userId];
              }
            }
          }
          return cb(null);
        });
      }
    };

    /*
      getBoard: (req,res,next) =>
        return res.json {},401 unless req.user
    
        board = 
          lanes: []
    
        @_getActiveProcessDefinitionId (err,processDefinitionId) =>
          return res.json board if err || !processDefinitionId
          #return next err if err
    
          @_stateMachineForAny (err, sm) =>
            return next err if err
    
    
            for state,i in sm.getSwimlanes() || []
              board.lanes.push
                label: state.label
                name: state.name
                order: i + 1
    
                activityDefinitions: [] # TBDeleted
                id: '' # TBDeleted
                totalTime : 0
                totalActiveTime : 0
                totalWaitingTime : 0 
                cards: []
    
            @dbStore.tasks.tasksForBoard {}, (err, pagedResult) =>
              return next err if err
              @dbStore.tasks.aggregatedTaskTimesForBoardPerState {}, (err,states) =>
                return next err if err
    
                laneMap = {}
                laneMap[lane.name] = lane for lane in board.lanes
    
                for task in pagedResult.items || []
    
                  lane = laneMap[task.state]
    
                  if lane
                    lane.cards.push 
                        id : task._id
                        desc : task.name || 'UNNAMED'
                        ready : task.stateCompleted
                        state : lane.name
                        totalActiveTime : task.totalActiveTime
                        totalWaitingTime: task.totalWaitingTime
                        totalTime :  task.totalActiveTime + task.totalWaitingTime
                        message: task.message || ''
                        isOnHold: task.onHold
                        updatedAt : task.updatedAt
                        userId : task.checkedOutByUserId
                        allowedRolesForStateTransition :  []
                        processDefinitionId : task.processDefinitionId
    
                for state,val of states
                  lane = laneMap[state]
                  if lane
                    _.extend lane, val
    
                for lane in board.lanes
                  lane.cards = _.sortBy lane.cards, (card) -> "#{card.isOnHold}-#{card.desc}"
    
                @_addUsernameToTasks board.lanes, (err) =>
                  @_addAllowedRolesForStateTransition board.lanes, (err) =>
                    res.json board
    */


    RoutesApi.prototype.getBoard2 = function(req, res, next) {
      var board,
        _this = this;
      if (!req.user) {
        return res.json({}, 401);
      }
      board = {
        lanes: []
      };
      return this._getActiveProcessDefinitionId(function(err, processDefinitionId) {
        if (err || !processDefinitionId) {
          return res.json(board);
        }
        return _this.dbStore.boards.firstBoard({}, function(err, boardData) {
          var boardCaption, boardName, i, _i, _len, _ref;
          if (err) {
            return next(err);
          }
          if (boardData) {
            _ref = boardData.states || [];
            for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
              boardName = _ref[i];
              boardCaption = boardName;
              if (boardData.captions && boardData.captions.length > i) {
                boardCaption = boardData.captions[i];
              }
              board.lanes.push({
                label: boardCaption,
                name: boardName,
                order: i + 1,
                activityDefinitions: [],
                id: '',
                totalTime: 0,
                totalActiveTime: 0,
                totalWaitingTime: 0,
                cards: []
              });
            }
            board.lanes.push({
              label: "Done",
              name: "done",
              order: board.lanes.length + 1,
              activityDefinitions: [],
              id: '',
              totalTime: 0,
              totalActiveTime: 0,
              totalWaitingTime: 0,
              cards: []
            });
          }
          return _this.dbStore.tasks.tasksForBoard({}, function(err, pagedResult) {
            if (err) {
              return next(err);
            }
            return _this.dbStore.tasks.tasksEndedForBoard({}, function(err, tasksEndedResult) {
              if (err) {
                return next(err);
              }
              return _this.dbStore.tasks.aggregatedTaskTimesForBoardPerState({}, function(err, states) {
                var doneLane, lane, laneMap, state, task, val, _j, _k, _l, _len1, _len2, _len3, _len4, _m, _ref1, _ref2, _ref3, _ref4;
                if (err) {
                  return next(err);
                }
                laneMap = {};
                _ref1 = board.lanes;
                for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
                  lane = _ref1[_j];
                  laneMap[lane.name] = lane;
                }
                _ref2 = pagedResult.items || [];
                for (_k = 0, _len2 = _ref2.length; _k < _len2; _k++) {
                  task = _ref2[_k];
                  lane = laneMap[task.state];
                  /*
                                  if task.onHold
                                    lane = laneMap["onhold"]
                  */

                  if (lane) {
                    lane.cards.push({
                      id: task._id,
                      desc: task.name || 'UNNAMED',
                      ready: task.stateCompleted,
                      state: lane.name,
                      totalActiveTime: task.totalActiveTime,
                      totalWaitingTime: task.totalWaitingTime,
                      totalTime: task.totalActiveTime + task.totalWaitingTime,
                      message: task.message || '',
                      isOnHold: task.onHold,
                      updatedAt: task.updatedAt,
                      userId: task.checkedOutByUserId,
                      allowedRolesForStateTransition: [],
                      processDefinitionId: task.processDefinitionId,
                      nextState: task.nextState,
                      taskEnded: false,
                      rejected: task.stateCompleted && task.taskRejected
                    });
                  }
                }
                doneLane = board.lanes[board.lanes.length - 1];
                _ref3 = tasksEndedResult.items || [];
                for (_l = 0, _len3 = _ref3.length; _l < _len3; _l++) {
                  task = _ref3[_l];
                  doneLane.cards.push({
                    id: task._id,
                    desc: task.name || 'UNNAMED',
                    ready: task.stateCompleted,
                    state: doneLane.name,
                    totalActiveTime: task.totalActiveTime,
                    totalWaitingTime: task.totalWaitingTime,
                    totalTime: task.totalActiveTime + task.totalWaitingTime,
                    message: task.message || '',
                    isOnHold: task.onHold,
                    updatedAt: task.updatedAt,
                    userId: task.checkedOutByUserId,
                    allowedRolesForStateTransition: [],
                    processDefinitionId: task.processDefinitionId,
                    nextState: task.nextState,
                    taskEnded: true,
                    rejected: false
                  });
                }
                for (state in states) {
                  val = states[state];
                  lane = laneMap[state];
                  if (lane) {
                    _.extend(lane, val);
                  }
                }
                _ref4 = board.lanes;
                for (_m = 0, _len4 = _ref4.length; _m < _len4; _m++) {
                  lane = _ref4[_m];
                  lane.cards = _.sortBy(lane.cards, function(card) {
                    return "" + card.isOnHold + "-" + card.desc;
                  });
                }
                return _this._addUsernameToTasks(board.lanes, function(err) {
                  return _this._addAllowedRolesForStateTransition(board.lanes, function(err) {
                    return res.json(board);
                  });
                });
              });
            });
          });
        });
      });
    };

    return RoutesApi;

  })();

}).call(this);
