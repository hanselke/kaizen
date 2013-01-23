Here is how it works:

ProcessDefinition has a StateMachine attached to it.
It is defined as:

allowedRolesToStart: ['role1','role2']
autoTransitionToStateOnStart: "xx"
states:
  start:
  end:
  state1:
    hideFromlane: true/false
    allowedRoles: ['role1','role2']
    formToShow: ''
    transitionToNextState: "function(task,options) { return "state2"};"
  state2:
    hideFromlane: true/false
  state3:
    hideFromlane: true/false

forms:


Each Task has:

currentCheckedOutUser
currentState:
isCurrentStateCompleted:
+timeInfo
nextState: Evaluated next state
taskData: {} 