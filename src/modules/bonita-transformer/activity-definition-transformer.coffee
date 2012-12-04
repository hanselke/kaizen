_ = require 'underscore-ext'

orderFromActivityDefinition = (activityDefinition) ->
  return 9999 unless activityDefinition.label && activityDefinition.label.length > 0 && activityDefinition.label.indexOf(" ") > 0
  label = activityDefinition.label.substr(0,activityDefinition.label.indexOf(" "))
  parseInt(label,0)


safeToString = (v) ->
  return "" unless v && _.isString(v)
  v

isEnd = (name) ->
  name = (name || '').toLowerCase()
  return true if name is "end"
  return false unless name.length > 3
  name = name.substr(0,4)
  return name is 'end_'

isStart = (name) ->
  name = (name || '').toLowerCase()
  return true if name is "start"
  return false unless name.length > 5
  name = name.substr(0,6)
  return name is 'start_'

isAssign = (name) ->
  name = (name || '').toLowerCase()
  return false unless name.length > 7
  name = name.substr(0,7)
  return name is 'assign_'

isState = (name) ->
  !isEnd(name) && !isStart(name) && !isAssign(name)

getGroup = (name) ->
  return "" if isStart(name) || isEnd(name)
  name = name.toLowerCase()
  return name.substr(7) if isAssign(name)
  name.substr(name.indexOf("_",1) + 1)

###
Takes an activity defintion and strips out all the junk
###
module.exports = (activityDefinition) ->
  return null unless activityDefinition

  result = 
    id : activityDefinition.uuid?.value
    name: activityDefinition.name || "" 
    label: activityDefinition.label
    order: orderFromActivityDefinition(activityDefinition)
    description: safeToString(activityDefinition.description)
    isStart: isStart(activityDefinition.name)
    isEnd: isEnd(activityDefinition.name)
    isAssign: isAssign(activityDefinition.name)
    isState: isState(activityDefinition.name)
    group: getGroup(activityDefinition.name)
###
{
   "description":"QA Checks",
   "name":"_1_Enter_Floor_Data",
   "label":"1 Enter Floor Data",
   "processDefinitionUUID":{
      "value":"QA_Data_Entry--1.5"
   },
   "uuid":{
      "value":"QA_Data_Entry--1.5--_1_Enter_Floor_Data"
   },
   "deadlines":{

   },
   "performers":{
      "string":"Floor"
   },
   "joinType":"XOR",
   "splitType":"AND",
   "connectors":{

   },
   "filter":{
      "@":{
         "class":"org.ow2.bonita.facade.def.element.impl.ConnectorDefinitionImpl"
      },
      "description":{

      },
      "className":"org.bonitasoft.connectors.bonita.filters.AssignedUserTaskFilter",
      "clientParameters":{
         "entry":{
            "string":"setActivityName",
            "Object-array":{
               "string":"Assign_enter_floor_data"
            }
         }
      },
      "throwingException":"true"
   },
   "dataFields":{

   },
   "outgoingTransitions":{
      "TransitionDefinition":[
         {
            "description":{

            },
            "name":"_1_Enter_Floor_Data__Assign_enter_floor_data",
            "processDefinitionUUID":{
               "value":"QA_Data_Entry--1.5"
            },
            "uuid":{
               "value":"QA_Data_Entry--1.5--_1_Enter_Floor_Data__Assign_enter_floor_data"
            },
            "condition":"shift1_Round1_Done == false",
            "from":"_1_Enter_Floor_Data",
            "to":"Assign_enter_floor_data",
            "isDefault":"false"
         },
         {
            "description":{

            },
            "name":"_1_Enter_Floor_Data__Assign_approve1",
            "processDefinitionUUID":{
               "value":"QA_Data_Entry--1.5"
            },
            "uuid":{
               "value":"QA_Data_Entry--1.5--_1_Enter_Floor_Data__Assign_approve1"
            },
            "condition":"shift1_Round1_Done == true",
            "from":"_1_Enter_Floor_Data",
            "to":"Assign_approve1",
            "isDefault":"false"
         }
      ]
   },
   "incomingTransitions":{
      "TransitionDefinition":{
         "description":{

         },
         "name":"Assign_enter_floor_data___1_Enter_Floor_Data",
         "processDefinitionUUID":{
            "value":"QA_Data_Entry--1.5"
         },
         "uuid":{
            "value":"QA_Data_Entry--1.5--Assign_enter_floor_data___1_Enter_Floor_Data"
         },
         "from":"Assign_enter_floor_data",
         "to":"_1_Enter_Floor_Data",
         "isDefault":"false"
      }
   },
   "boundaryEvents":{

   },
   "subflowInParameters":{

   },
   "subflowOutParameters":{

   },
   "asynchronous":"false",
   "executingTime":"0",
   "priority":"0",
   "inCycle":"true",
   "outgoingEvents":{

   },
   "type":"Human",
   "loop":"false",
   "beforeExecution":"false",
   "catchEvent":"false",
   "terminateProcess":"false"
}
###

