if (parent && parent.window && parent.window.angular && parent.window.angular.scenario) {
  (function(){
    window.alert = function(msg) {
      console.log('ALERT:',msg);
    }
  })();
}
AppController.$inject = ['$resource', '$route', '$location', '$xhr', '$defer', '$window'];
function AppController($resource, $route, $location, $xhr, $defer, $window){
  $route.parent(this);
  this.$route = $route;
  this.$location = $location;
  this.$xhr = $xhr;
  this.$defer = $defer;
  this.$window = $window
  this.$xhr.defaults.headers.post['Content-Type']='application/json';

  this.getset = function(var_name, getter, setter) {
    this.__defineGetter__(var_name, getter)
    this.__defineSetter__(var_name, setter)
  }

  this.COUNTRY_CODES = COUNTRY_CODES;

  //the HTTP actions used by the application. verifyCache=true is needed to
  //prevent caching by angular
  var actions = {
    'get':    {method:'GET', verifyCache: true},
    'save':   {method:'POST'},
    'query':  {method:'GET', isArray:true, verifyCache: true},
    'remove': {method:'DELETE'},
    'delete': {method:'DELETE'}
  }
  this.Registration = $resource('/users/:id', {id: '@id'}, actions);
  this.Login = $resource('/login', {}, actions);

  this.results = [];
  // this.currentUser can have 3 possible values:
  // - undefined: didn't receive the response for GET /api/session, so we
  //      don't know if there is a signed in user or not
  // - null: there is no signed in user
  // - an object: the signed in user's properties
  this.currentUser = undefined;
  this.loadCurrentUser();
  var flash = ''
  this.getset('flash',
    function() {var current_flash = flash; flash = ''; return current_flash},
    function(new_flash) {flash = new_flash})

  this.roles = ['fax', 'customer', 'backoffice', 'sales', 'purchasing', 'admin']
  var chat_lines = []
  this.getset('chat_lines',
    function() {return chat_lines},
    function(new_chat_lines) {chat_lines = new_chat_lines})
  this.chat_socket = io.connect('/')
  var that = this
  this.chat_socket.on('connect', function(){
    if (that.currentUser) {
      that.chat_socket.emit('nick', {nick: that.currentUser.name})
      that.$digest()
    }
  })
}
AppController.prototype = {
  log: function(data){
    if (console && typeof(console.log) == 'function') { console.log(data) }
    return data;
  },
  objectValues: function(obj){
    var arr = []
    for (var k in obj) arr.push(obj[k])
    return arr
  },
  getItem: function(name, defaultValue){
    if (localStorage && (typeof(localStorage.getItem) == 'function') && (name in localStorage)) {
      return localStorage.getItem(name)
    }
    return defaultValue
  },
  setItem: function(name, value){
    if (localStorage && typeof(localStorage.setItem) == 'function') {
      localStorage.setItem(name, value)
    }
  },
  setRole: function(role){ var that = this
    this.$xhr('POST', '/set_role', {role: role}, function(code, response) {
      that.setCurrentUser(response);
    }, that.errorHandler);
  },
  getRoleClass: function(role) { return (this.currentUser && this.currentUser.roles.indexOf(role) >= 0) ? 'on' : '' },
  errorHandler: function(code, error) {
    var field // backend can send back a field name so it can be focused
    if (typeof(error) == 'object') { field = error.field; error = error.msg }
    if (!error) { error = code+': Unknown error!' }
    this.$window.alert(error);
    if (code == 401) { // Unauthorized => show signin form
      this.currentUser = undefined
    }
    if (field) this.$defer(function(){ $('input[name="'+field+'"]').focus().select() })
  },
  isUserSignedIn: function() {
    return this.currentUser && this.currentUser.email ? true : false; //need to return false explicitly
  },
  loadCurrentUser: function() { var that = this
    this.$xhr('GET', '/api/session',
      function(code, res) { that.setCurrentUser(res)},
      // avoid calling error handler if the only problem is the lack of logged in user
      function(code, res){ that.setCurrentUser(null)
        if (code != 404) that.errorHandler(code, res)
        else that.$location.path('signin')})
  },
  setCurrentUser: function(user) {
    this.currentUser = user;
    if (user && user.name) this.chat_socket.emit('nick', {nick: user.name})
  },
  signout: function() { var that = this
    if (!this.isUserSignedIn()) return
    this.$xhr('POST', '/logout', {}, function(code, response) {
      that.setCurrentUser(undefined);
      that.$location.path('signin')
    }, this.errorHandler);
  },
  hasRole: function(role) {
    if (!this.isUserSignedIn() || !this.currentUser.roles) return false
    return this.currentUser.roles.indexOf(role) >= 0
  },
  nextTask: function(cb) { var that = this
    var processInstanceUUID = null

    _.each(window.lanesBoard || [], 
      function(lane) {
        _.each(lane.cards || [],function(card) {
          if(!processInstanceUUID) {
            processInstanceUUID = card.processInstance;
          }
        }); 
      }
    );

    if(processInstanceUUID) {
      this.$xhr('GET', '/api/tasks?procInstUUID=' + processInstanceUUID, function(code, bods) {
        that.$parent.$root.$emit('refresh_board_event');
        (cb || that.goto_task_view)(that.bod = bods[0])
      }, this.errorHandler)
    } else {
      alert("There is nothing to do at the moment");
    }
  },
  goto_task_view: function(bod) {
    if (!bod) { return this.$window.alert('There is nothing to do at the moment') }
    var name = bod.name
    var sender = bod.ApplicationArea.Sender

    var view = undefined
    if (name == 'ProcessFax') view = '/backoffice-sales-rfq'
    if (name == 'ProcessSalesOrder' && sender == 'sales') view = '/sales-rfq'
    if (name == 'SyncSalesOrder' && sender == 'purchasing') view = '/purchasing-rfq'
    if (name == 'SyncSalesOrder' && sender == 'sales') view = '/sales-quote'
    if (name == 'ProcessRFQ') view = '/backoffice-supplier-rfq'
    if (name == 'ProcessQuote') view = '/backoffice-customer-quote'

    if (view) { this.$location.path(view) }
    else console.log('unknown bod name and sender:', name, sender)
  },
  newRFQ: function(){ var that = this
    this.$xhr('GET', '/process_rfq.json', function(code, res){
      that.bod = res
      that.$location.path('/backoffice-sales-rfq')
    })
  },
  newPO: function(){ var that = this
    this.$xhr('GET', '/process_po.json', function(code, res){
      that.bod = res
      that.$location.path('/backoffice-sales-po')
    })
  }
}


