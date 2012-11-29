###
App service which is responsible for the main configuration of the app.
###
myModule = angular.module("myModule", [])

angular.module("myModule", []).config ["$routeProvider", ($routeProvider) ->
  $routeProvider.when("/",
    templateUrl: "main"
    controller: MainController
  ).when("/task/:taskId",
    templateUrl: "task"
    controller: TaskController
  ).otherwise redirectTo: "/"
]

