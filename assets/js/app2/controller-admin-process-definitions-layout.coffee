class window.AdminProcessDefinitionsLayoutController
  constructor: (@$scope,@$http,@$location,@$routeParams) ->
    @$scope.processDefinition = {}
    @$scope.create = @create
    @$scope.processDefinition.name = "(loading...)"
    @$scope.uploadFiles = @uploadFiles
    @$scope.uploadFilesLayout = @uploadFilesLayout

    @load @$routeParams.processDefinitionId

    # Layout
    @$scope.uploaderLayout = new plupload.Uploader
      runtimes: "html5,flash,silverlight,html4"
      browse_button: "pickfilesLayout"
      container: "uploadContainerLayout"
      multi_selection : false
      multipart : true
      chunk_size : '10mb'
      max_file_size: "10mb"
      drop_element: 'dropAreaLayout'
      url: "http://#{document.location.host}/api/admin/process-definitions/#{@$routeParams.processDefinitionId}/layout"
      flash_swf_url: "/lib/plupload/Moxie.swf"
      silverlight_xap_url: "/lib/plupload/Moxie.xap"
      filters: [ {title: "Exported Layout Files",extensions: "json"}]

    @$scope.uploaderLayout.bind "FilesAdded", (up, files) =>
      @$scope.$apply()
    @$scope.uploaderLayout.bind "QueueChanged", (up, files) =>
      @$scope.$apply()
    @$scope.uploaderLayout.bind "FileUploaded", (up, file,response) =>
          alert "File uploaded"
          @$scope.$apply()
          @$location.path '/admin/process-definitions'


    @$scope.uploaderLayout.bind "UploadProgress", (up, file) =>
      @$scope.$apply()
      #$(file.id).getElementsByTagName("b")[0].innerHTML = "<span>" + file.percent + "%</span>"

    @$scope.uploaderLayout.init()


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

window.AdminProcessDefinitionsLayoutController.$inject = ['$scope',"$http","$location","$routeParams"]
