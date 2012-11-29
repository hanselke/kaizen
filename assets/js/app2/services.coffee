###
App service which is responsible for the main configuration of the app.
###
myModule = angular.module("myModule", [])

rpFn = ($routeProvider) ->
  $routeProvider.when("/", {templateUrl: "main", controller: MainController})
                .when("/task", {templateUrl: "task",controller: TaskController})
                .otherwise redirectTo: "/"

angular.module("myModule", []).config ["$routeProvider", rpFn]

