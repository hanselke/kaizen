
window.myFilters = angular.module 'myFilters', []

window.myFilters.filter 'gravatar', () ->
  return (email) ->
    return "/img/placeholders/avatar-50x50.jpg" unless email

    "http://www.gravatar.com/avatar/#{md5(email)}"
