###
App service which is responsible for the main configuration of the app.
###


myModule = angular.module("myModule", [window.myFilters])

rpFn = ($routeProvider) ->
  $routeProvider.when("/", {templateUrl: "main", controller: MainController})
                .when("/task/:taskId", {templateUrl: "task",controller: TaskController})
                .when("/admin/users", {templateUrl: "admin/users",controller: AdminUsersController})
                .when("/admin/users/add", {templateUrl: "admin/users/add",controller: AdminUsersAddController})
                .when("/admin/boards", {templateUrl: "admin/boards",controller: AdminBoardsController})
                .when("/admin/boards/add", {templateUrl: "admin/boards/add",controller: AdminBoardsAddController})
                .when("/admin/process-definitions", {templateUrl: "admin/process-definitions",controller: AdminProcessDefinitionsController})
                .when("/admin/process-definitions/add", {templateUrl: "admin/process-definitions/add",controller: AdminProcessDefinitionsAddController})
                .when("/admin/process-definitions/:processDefinitionId/form", {templateUrl: "admin/process-definitions/form",controller: AdminProcessDefinitionsFormController})
                .when("/admin/process-definitions/:processDefinitionId/layout", {templateUrl: "admin/process-definitions/layout",controller: AdminProcessDefinitionsLayoutController})
                .when("/admin/process-definitions/:processDefinitionId/edit", {templateUrl: "admin/process-definitions/edit",controller: AdminProcessDefinitionEditController})
                .when("/admin/process-definitions/:processDefinitionId/validate", {templateUrl: "admin/process-definitions/validate",controller: AdminProcessDefinitionValidateController})
                .when("/admin/tasks", {templateUrl: "admin/tasks",controller: AdminTasksController})
                .when("/admin/roles", {templateUrl: "admin/roles",controller: AdminRolesController})
                .when("/admin/roles/add", {templateUrl: "admin/roles/add",controller: AdminRolesAddController})
                .when("/admin/change-password", {templateUrl: "admin/change-password",controller: AdminChangePasswordController})
                .when("/help", {templateUrl: "help",controller: HelpController})
                .when("/help/setup", {templateUrl: "help/setup",controller: HelpController})
                .when("/help/terms", {templateUrl: "help/terms",controller: HelpController})
                .otherwise redirectTo: "/"

angular.module("myModule", ['myFilters']).config ["$routeProvider", rpFn]
