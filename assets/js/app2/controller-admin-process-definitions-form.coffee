class window.AdminProcessDefinitionsFormController
  constructor: (@$scope,@$http,@$location,@$routeParams) ->
    @$scope.processDefinition = {}
    @$scope.create = @create
    @$scope.processDefinition.name = "(loading...)"
    @$scope.uploadFiles = @uploadFiles
    @$scope.uploadFilesLayout = @uploadFilesLayout

    @load @$routeParams.processDefinitionId


    @$scope.uploader = new plupload.Uploader
      runtimes: "html5,flash,silverlight,html4"
      browse_button: "pickfiles"
      container: "uploadContainer"
      multi_selection : false
      multipart : true
      chunk_size : '1mb'
      max_file_size: "10mb"
      drop_element: 'dropArea'
      url: "http://#{document.location.host}/api/admin/process-definitions/#{@$routeParams.processDefinitionId}/excel"
      flash_swf_url: "/lib/plupload/Moxie.swf"
      silverlight_xap_url: "/lib/plupload/Moxie.xap"
      filters: [ {title: "Excel Files",extensions: "xlsx"}]

    @$scope.uploader.bind "FilesAdded", (up, files) =>
      @$scope.$apply()
    @$scope.uploader.bind "QueueChanged", (up, files) =>
      @$scope.$apply()


    @$scope.uploader.bind "UploadProgress", (up, file) =>
      @$scope.$apply()
      #$(file.id).getElementsByTagName("b")[0].innerHTML = "<span>" + file.percent + "%</span>"

    @$scope.uploader.bind "FileUploaded", (up, file,response) =>
          alert "File uploaded"
          @$scope.$apply()
          @$location.path '/admin/process-definitions'

    @$scope.uploader.init()


  uploadFiles: () =>
    @$scope.uploader.start()
    false

  uploadFilesLayout: () =>
    @$scope.uploaderLayout.start()
    false

  load: (processDefinitionId) =>
    request = @$http.get "/api/admin/process-definitions/#{processDefinitionId}"
    request.error @$scope.errorHandler
    request.success (data, status, headers, config) =>
      _.extend @$scope.processDefinition,data


  update: (processDefinition) =>
    ###
    request = @$http.post "/api/admin/process-definitions",processDefinition
    request.error @$scope.errorHandler
    request.success (data, status, headers, config) =>
      #@$scope.processDefinitions = data.items
      @$location.path '/admin/process-definitions'
      @$scope.flashMessage "New Process Definition Created"
    ###

window.AdminProcessDefinitionsFormController.$inject = ['$scope',"$http","$location","$routeParams"]
