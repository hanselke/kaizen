loadCssFile = (pathToFile) ->
  css = jQuery("<link>")
  css.attr
    rel: "stylesheet"
    type: "text/css"
    href: pathToFile

  $("head").append css


class window.TaskController
  constructor: (@$scope,@$http,@$routeParams) ->
    #alert "GOT: #{@$routeParams.taskId}"

    @$scope.taskChanges = {}

    loadCssFile "/api/process-definitions/50d22f260b75ca1d9000000c/form-css"
    $(".xlsl-form-container").load "/api/process-definitions/50d22f260b75ca1d9000000c/form-html", () =>
      $(".xlsl-form-container input").focusout () =>
        #


window.TaskController.$inject = ['$scope',"$http",'$routeParams']


