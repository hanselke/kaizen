

function SigninController() {
  this.email = this.getItem('email')
  var focus = 'email'
  if (this.email) focus = 'password'
  this.$defer(function(){ $('input[name="'+focus+'"]').focus() }, 100)
}
SigninController.prototype = {
  submit: function() {
    var r = new this.Login({
      'email': this.email,
      'password': this.password
    })
    var that = this;
    r.$save({}, function(obj) {
      that.setItem('email', that.email) //store email of last successful sign in
      that.$location.path('/main')
      that.loadCurrentUser()
      that.password = ''
    }, this.errorHandler)
  },
  cancel: function() {
    this.$location.path('/main')
  }
}
