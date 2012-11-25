###
A helper class that is exposed as a dynamic helper by @see RoutesUsers
@note
Parameterless routes are exposed as values while routes that take a parameter are functions.
###
module.exports = class RoutesUsersPathHelper
  signIn: "/users/sign-in"
  resetPassword: "/users/reset-password"
  resetPasswordReset: '/users/reset-password/reset'
  changePassword: "/users/change-password"
  signOut: "/users/sign-out"
  completeSignUp: "/users/complete-sign-up"

