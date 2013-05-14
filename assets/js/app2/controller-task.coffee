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
    @$scope.onHold = @onHold
    @$scope.cancel = @cancel
    @$scope.isFormStateActive = false
    @$scope.isFormYesNo = false
    @$scope.currentForm = null
    @$scope.currentTaskName = null
    @$scope.taskMessage = ""
    @$scope.editAllStates = !!@$routeParams['editAllStates'] # TODO SET THIS RIGHT

    @loadFormData()

    @$scope.formulas = []

  taskCompletedYes: () =>
    data =
      fields: {}

    for key,val of @$scope.currentForm.fields when val.field && val.field.length > 0
      data.fields[val.field] = true

    data.isRejected = false

    @taskCompleted data

  taskCompletedNo: () =>
    data =
      fields: {}

    for key,val of @$scope.currentForm.fields when val.field && val.field.length > 0
      data.fields[val.field] = false

    data.isRejected = true

    @taskCompleted data

  taskCompleted: (resultData = {}) =>
    if @$scope.activeTaskId
      taskId = @$scope.activeTaskId

      resultData.message= @$scope.taskMessage

      request = @$http.post "/api/tasks/#{taskId}/complete", resultData
      request.error (data, status, headers, config) =>
        @$scope.flashMessage "Failed to complete task - please try again"
      request.success (data, status, headers, config) =>

        @$scope.currentForm = null
        @$location.path "/"
        # Flash here

  cancel: (resultData = {}) =>
    if @$scope.activeTaskId
      taskId = @$scope.activeTaskId

      request = @$http.post "/api/tasks/#{taskId}/cancel", {}
      request.error (data, status, headers, config) =>
        @$scope.flashMessage "Failed to cancel task - please try again"
      request.success (data, status, headers, config) =>

        @$scope.currentForm = null
        @$location.path "/"
        # Flash here

  onHold: (resultData = {}) =>
    if @$scope.activeTaskId
      taskId = @$scope.activeTaskId

      request = @$http.post "/api/tasks/#{taskId}/onhold", {}
      request.error (data, status, headers, config) =>
        @$scope.flashMessage "Failed to put the task on hold - please try again"
      request.success (data, status, headers, config) =>

        @$scope.currentForm = null
        @$location.path "/"
        # Flash here

  loadFormData: =>
    cacheBuster = "#{new Date().getTime()}"
    request = @$http.get "/api/tasks/#{@$routeParams.taskId}/data"
    request.error @$scope.errorHandler
    request.success (result, status, headers, config) =>
      @$scope.currentTaskName = result.taskName
      @$scope.taskMessage  = result.taskMessage

      loadCssFile "/api/process-definitions/#{result.processDefinitionId}/form-css?cb=#{cacheBuster}"
      $(".xlsl-form-container").load "/api/process-definitions/#{result.processDefinitionId}/#{@$routeParams.taskId}/form-html?cb=#{cacheBuster}&editAllStates=#{@$scope.editAllStates}", () =>
        $(".xlsl-form-container input").focusout @onFocusout
        for row in result.items

          $("input.r-#{row.r}.c-#{row.c}").val(row.v)
          $("span.r-#{row.r}.c-#{row.c}").text(row.v)

        @$scope.formulas = []

        $(".xlsl-form-container .formula-element").each (i,v) =>
          @$scope.formulas.push
            el : $(v)
            formula: $(v).data('formula')

        @$scope.isFormYesNo = !!result.form
        @$scope.currentForm = result.form
        @$scope.isFormStateActive = true

        @calculateSheet()

        @$scope.$apply()

  onFocusout: (e) =>
    $target = $(e.target)

    payload = @calculateSheet()

    payload.push
      r: $target.data('row')
      c: $target.data('cell')
      v: $target.val()

    request = @$http.post "/api/tasks/#{@$routeParams.taskId}/data", payload


  getCellValue: (rowFromZero,colFromZero) =>
    $inputV = $(".xlsl-form-container input.r-#{rowFromZero}.c-#{colFromZero}")
    $spanV =  $(".xlsl-form-container span.r-#{rowFromZero}.c-#{colFromZero}")

    if $inputV.length == 1
      return parseFloat($inputV.val())
    if $spanV.length == 1
      return parseFloat($spanV.text())

    return 0

  ###
  Calculates all formulas and returns an array of calculated values
  ###
  calculateSheet: () =>
    results = []

    window.resolveCell = (row,col) =>
      rowInt = parseInt(row) - 1
      col = col.toLowerCase()
      colInt = 0
      for i in [0..col.length - 1]
        c = col.charCodeAt(i) - 'a'.charCodeAt(i)
        colInt += (col.length - i) * c

      return @getCellValue(rowInt,colInt) || 0

    for formula in @$scope.formulas
      try 
        f = formula.formula.replace(/\s+/g, ' ') # We need to remove whitespace for peg
        res = window.parser.parse(f)
        formula.el.text res
        results.push
          r: formula.el.data('row')
          c: formula.el.data('cell')
          v: res

      catch e
        formula.el.text "#error"

    return results


window.TaskController.$inject = ['$scope',"$http",'$routeParams','$location']


