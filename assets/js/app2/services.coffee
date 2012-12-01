###
App service which is responsible for the main configuration of the app.
###
myModule = angular.module("myModule", [])

rpFn = ($routeProvider) ->
  $routeProvider.when("/", {templateUrl: "main", controller: MainController})
                .when("/task", {templateUrl: "task",controller: TaskController})
                .when("/admin/users", {templateUrl: "admin/users",controller: AdminUsersController})
                .otherwise redirectTo: "/"

angular.module("myModule", []).config ["$routeProvider", rpFn]

