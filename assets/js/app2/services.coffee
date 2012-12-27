###
App service which is responsible for the main configuration of the app.
###
myModule = angular.module("myModule", [window.myFilters])


rpFn = ($routeProvider) ->
  $routeProvider.when("/", {templateUrl: "main", controller: MainController})
                .when("/task", {templateUrl: "task",controller: TaskController})
                .when("/admin/users", {templateUrl: "admin/users",controller: AdminUsersController})
                .when("/admin/users/add", {templateUrl: "admin/users/add",controller: AdminUsersAddController})
                .when("/admin/process-definitions", {templateUrl: "admin/process-definitions",controller: AdminProcessDefinitionsController})
                .when("/admin/process-definitions/add", {templateUrl: "admin/process-definitions/add",controller: AdminProcessDefinitionsAddController})
                .when("/admin/process-definitions/:processDefinitionId/form", {templateUrl: "admin/process-definitions/form",controller: AdminProcessDefinitionsFormController})
                .otherwise redirectTo: "/"

angular.module("myModule", ['myFilters']).config ["$routeProvider", rpFn]

