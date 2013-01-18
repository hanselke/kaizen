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

    @loadFormData()

  loadFormData: =>
    request = @$http.get "/api/tasks/#{@$routeParams.taskId}/data"
    request.error @$scope.errorHandler
    request.success (result, status, headers, config) =>
      loadCssFile "/api/process-definitions/#{result.processDefinitionId}/form-css"
      $(".xlsl-form-container").load "/api/process-definitions/#{result.processDefinitionId}/form-html", () =>
        $(".xlsl-form-container input").focusout @onFocusout
        for row in result.items
          $("input.r-#{row.r}.c-#{row.c}").val(row.v)


  onFocusout: (e) =>
    $target = $(e.target)

    payload = [
      r: $target.data('row')
      c: $target.data('cell')
      v: $target.val()
    ]

    request = @$http.post "/api/tasks/#{@$routeParams.taskId}/data", payload
    #request.error @$scope.errorHandler
    #request.success (data, status, headers, config) =>


    #alert "focusout #{$(e.target).val()}"

window.TaskController.$inject = ['$scope',"$http",'$routeParams']


