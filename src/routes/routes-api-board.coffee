_ = require 'underscore'
async = require 'async'
winston = require 'winston'
errors = require 'some-errors'
fs = require 'fs'
xlsxToForm = require '../modules/xlsx-to-form'
stateMachinePackage = require '../modules/state-machine'
stateMachineForProcessDefinition = require './helpers/state-machine-for-process-definition'

mongoose = require "mongoose"
ObjectId = mongoose.Types.ObjectId



module.exports = class RoutesApi


  constructor:(settings) ->
    _.extend @,settings
    throw new Error("app parameter is required") unless @app
    throw new Error("identityStore parameter is required") unless @identityStore

  setupLocals: () =>

  setupRoutes: () =>
    @app.get  '/api/board', @getBoard2

  _stateMachineForProcessDefinitionId: (processDefinitionId, cb) =>
    @dbStore.processDefinitions.get processDefinitionId,null,true, (err,item) =>
      return next err if err
      stateMachineForProcessDefinition item, (err, sm) =>
        cb err,sm

    ###
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
    ###

  _stateMachineForAny: (cb) =>
    @dbStore.processDefinitions.getValidProcessDefinition {select: '_id stateMachine name'}, (err,processDefinition) =>
      return cb err if err
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
 

  _getActiveProcessDefinitionId: (next) =>
    @dbStore.processDefinitions.firstProcessDefinition {select: '_id'}, (err,processDefinition) =>
      return next err if err
      return next new Error("Process definition not found") unless processDefinition
      next null, processDefinition._id


  _addUsernameToTasks: (lanes, cb) =>
    @usernameMap = {} unless @usernameMap 
    @rolesMap = {} unless @rolesMap 

    unresolvedUserIds = {}

    for lane in lanes
      for card in lane.cards
        if card.userId
          card.username = @usernameMap[card.userId]
          card.roles = @rolesMap[card.userId] || []
          unresolvedUserIds[card.userId] = true unless @usernameMap[card.userId]

    if _.keys(unresolvedUserIds).length == 0 
      cb null # All done
    else

      idList = _.map _.keys(unresolvedUserIds), (x) -> new ObjectId x.toString()
      @identityStore.models.User.find({}).where('_id').in(idList).select('_id username roles').exec (err, items) =>
        return cb err if err
        items ||= []

        for item in items
          @usernameMap[item._id.toString()] = item.username 
          @rolesMap[item._id.toString()] = item.roles || []

        for lane in lanes
          for card in lane.cards
            card.username = @usernameMap[card.userId] if card.userId
            card.roles = @rolesMap[card.userId] if card.userId
        cb null

  getBoard: (req,res,next) =>
    return res.json {},401 unless req.user

    board = 
      lanes: []

    @_getActiveProcessDefinitionId (err,processDefinitionId) =>
      return res.json board if err || !processDefinitionId
      #return next err if err

      @_stateMachineForAny (err, sm) =>
        return next err if err

        ###
        board.lanes.push
          label: "On Hold"
          name: "onhold"
          order: 0

          activityDefinitions: [] # TBDeleted
          id: '' # TBDeleted
          totalTime : 0
          totalActiveTime : 0
          totalWaitingTime : 0 
          cards: []
        ###

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

              ###
              if task.onHold
                lane = laneMap["onhold"]
              ###

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

            for state,val of states
              lane = laneMap[state]
              if lane
                _.extend lane, val

            for lane in board.lanes
              lane.cards = _.sortBy lane.cards, (card) -> "#{card.isOnHold}-#{card.desc}"

            @_addUsernameToTasks board.lanes, (err) =>
              res.json board



  getBoard2: (req,res,next) =>
    return res.json {},401 unless req.user

    board = 
      lanes: []

    @_getActiveProcessDefinitionId (err,processDefinitionId) =>
      return res.json board if err || !processDefinitionId
      #return next err if err


      @dbStore.boards.firstBoard {}, (err,boardData) =>
        return next err if err

        if boardData 
          for boardName,i in boardData.states || []
            boardCaption = boardName
            if boardData.captions && boardData.captions.length > i
              boardCaption = boardData.captions[i]

            board.lanes.push
              label: boardCaption
              name:  boardName
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

              ###
              if task.onHold
                lane = laneMap["onhold"]
              ###

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

            for state,val of states
              lane = laneMap[state]
              if lane
                _.extend lane, val

            for lane in board.lanes
              lane.cards = _.sortBy lane.cards, (card) -> "#{card.isOnHold}-#{card.desc}"

            @_addUsernameToTasks board.lanes, (err) =>
              res.json board

