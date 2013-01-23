loadCssFile = (pathToFile) ->
  css = jQuery("<link>")
  css.attr
    rel: "stylesheet"
    type: "text/css"
    href: pathToFile

  $("head").append css


class window.TaskController
  constructor: (@$scope,@$http,@$routeParams,@$location) ->
    #alert "GOT: #{@$routeParams.taskId}"

    @$scope.taskChanges = {}
    @$scope.taskCompleted = @taskCompleted
    @$scope.taskCompletedYes = @taskCompletedYes
    @$scope.taskCompletedNo = @taskCompletedNo
    @$scope.isFormStateActive = false
    @$scope.isFormYesNo = false
    @$scope.currentForm = null

    @loadFormData()

  taskCompletedYes: () =>
    data =
      fields: {}

    for key,val of @$scope.currentForm.fields when val.field && val.field.length > 0
      data.fields[val.field] = true

    @taskCompleted data

  taskCompletedNo: () =>
    data =
      fields: {}

    for key,val of @$scope.currentForm.fields when val.field && val.field.length > 0
      data.fields[val.field] = false

    @taskCompleted data

  taskCompleted: (resultData = {}) =>
    if @$scope.activeTaskId
      taskId = @$scope.activeTaskId

      request = @$http.post "/api/tasks/#{taskId}/complete", resultData
      request.error (data, status, headers, config) =>
        @$scope.flashMessage "Failed to complete task - please try again"
      request.success (data, status, headers, config) =>

        @$scope.currentForm = null
        @$location.path "/"
        # Flash here

  loadFormData: =>
    request = @$http.get "/api/tasks/#{@$routeParams.taskId}/data"
    request.error @$scope.errorHandler
    request.success (result, status, headers, config) =>
      loadCssFile "/api/process-definitions/#{result.processDefinitionId}/form-css"
      $(".xlsl-form-container").load "/api/process-definitions/#{result.processDefinitionId}/#{@$routeParams.taskId}/form-html", () =>
        $(".xlsl-form-container input").focusout @onFocusout
        for row in result.items
          $("input.r-#{row.r}.c-#{row.c}").val(row.v)

        @$scope.isFormYesNo = !!result.form
        @$scope.currentForm = result.form
        @$scope.isFormStateActive = true
        @$scope.$apply()

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

window.TaskController.$inject = ['$scope',"$http",'$routeParams','$location']


