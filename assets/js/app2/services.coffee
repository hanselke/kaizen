###
App service which is responsible for the main configuration of the app.
###

angular.module("Notification", []).factory("$flash", ($rootScope) ->
  service = notify: (level, message, element, callback) ->
    notification =
      level: level
      message: message
      element: (element or "default")
      callback: callback

    $rootScope.$emit "event:ngNotification", notification

  service
).directive "ngNotice", ($rootScope) ->
  noticeObject =
    replace: false
    transclude: false
    link: (scope, element, attr) ->
      $rootScope.$on "event:ngNotification", (event, notification) ->
        if attr.ngNotice is notification.element
          element.html "<span class=\"" + notification.level + "\">" + notification.message + "</span>"
          notification.callback()  if typeof notification.callback is "function"

      element.attr "ng-notice", (attr.ngNotice or "default")

  noticeObject


myModule = angular.module("myModule", [window.myFilters,'Notification'])

rpFn = ($routeProvider) ->
  $routeProvider.when("/", {templateUrl: "main", controller: MainController})
                .when("/task/:taskId", {templateUrl: "task",controller: TaskController})
                .when("/admin/users", {templateUrl: "admin/users",controller: AdminUsersController})
                .when("/admin/users/add", {templateUrl: "admin/users/add",controller: AdminUsersAddController})
                .when("/admin/process-definitions", {templateUrl: "admin/process-definitions",controller: AdminProcessDefinitionsController})
                .when("/admin/process-definitions/add", {templateUrl: "admin/process-definitions/add",controller: AdminProcessDefinitionsAddController})
                .when("/admin/process-definitions/:processDefinitionId/form", {templateUrl: "admin/process-definitions/form",controller: AdminProcessDefinitionsFormController})
                .when("/help", {templateUrl: "help",controller: HelpController})
                .when("/help/setup", {templateUrl: "help/setup",controller: HelpController})
                .when("/help/terms", {templateUrl: "help/terms",controller: HelpController})
                .otherwise redirectTo: "/"

angular.module("myModule", ['myFilters','Notification']).config ["$routeProvider", rpFn]
