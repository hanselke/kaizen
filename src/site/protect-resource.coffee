module.exports = protectResourceSetup = (opts = {}) ->
  protectResourceHandle = (req, res, next) ->
    return res.redirect("/users/sign-in?next=#{encodeURIComponent(req.url)}") unless req.user
    next()
  return protectResourceHandle