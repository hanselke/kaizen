
function RegisterController() {
}
RegisterController.prototype = {
  submit: function() {
    var r = new this.Registration({
      'email': this.email,
      'password': this.password,
      'password2': this.password2,
      'company_name': this.company_name
    });
    var that = this;
    r.$save({}, function(obj) {
      that.$location.path('/main');
      //the registered user will be automatically signed-in in the backend, so we need to get the current user
      that.loadCurrentUser();
    }, this.errorHandler);
  },
  cancel: function() {
    this.$location.path('/main');
  }
}

