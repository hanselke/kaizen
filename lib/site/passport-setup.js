// Generated by CoffeeScript 1.4.0
(function() {
  var BasicStrategy, PassportBearerStrategy, PassportLocalStrategy, color, errors, failureRedirect, getProfileUrl, passport, successRedirect, trace, winston;

  color = require('colors');

  winston = require('winston');

  passport = require('passport');

  errors = require('some-errors');

  BasicStrategy = require('passport-http').BasicStrategy;

  PassportLocalStrategy = require('passport-local').Strategy;

  PassportBearerStrategy = require('passport-local').Strategy;

  trace = require('../util/trace');

  getProfileUrl = function(username) {
    return "/" + username;
  };

  successRedirect = "/";

  failureRedirect = "/";

  module.exports = function(expressApp, identityStore, config, baseUrl) {
    if (!expressApp) {
      throw new Error("expressApp required");
    }
    if (!identityStore) {
      throw new Error("identityStore required");
    }
    if (!config) {
      throw new Error("config required");
    }
    if (!baseUrl) {
      throw new Error("baseUrl required");
    }
    passport.serializeUser(function(user, done) {
      return done(null, user.id || user._id);
    });
    passport.deserializeUser(function(id, done) {
      return identityStore.users.get(id, function(err, user) {
        if (err) {
          winston.error("deserializeUser: " + (JSON.stringify(err)));
        }
        if (err) {
          return done(new errors.ClearPassportSession);
        }
        return done(null, user);
      });
    });
    return passport.use(new PassportLocalStrategy(function(username, password, done) {
      var _this = this;
      return identityStore.users.validateUserByUsernameOrEmail(username, password, function(err, user) {
        console.log("DID IT WORK OUT: " + err + " " + (JSON.stringify(user)));
        if (err) {
          return done(err);
        }
        return done(null, user);
      });
    }));
    /*
      passport.use new PassportBearerStrategy (token, done) ->
        identityStore.tokenInfos.validate token, (err, tokenInfo) ->
          trace "Validating Token COMPLETE: #{token}"
          return done err if err
          return done null, null unless tokenInfo && tokenInfo.actor
          done null, tokenInfo.actor
    */

    /*
      postLoginFacebook = (req, res, next) =>
        res.redirect req.body.next || req.query.next || successRedirect #getProfileUrl(user.username)
    
      step2Conf =
        successRedirect: successRedirect
        failureRedirect: failureRedirect
        failureFlash: true
    
      # Facebook
      facebookConfig = 
        clientID: config.get 'auth:facebook:key'
        clientSecret: config.get 'auth:facebook:secret'
        callbackURL: "#{baseUrl}/users/auth/facebook/callback"
      passport.use new FacebookStrategy facebookConfig, (accessToken, refreshToken, profile, done) ->
        identityStore.identities.createOrValidate "facebook",  accessToken, refreshToken, profile,null, done
        
      expressApp.get "/users/auth/facebook", passport.authenticate("facebook", scope: 'email' )
      expressApp.get "/users/auth/facebook/callback", passport.authenticate("facebook", step2Conf), postLoginFacebook
      winston.info "Registered service provider: " + "Facebook".cyan + " for app id: " + config.get('auth:facebook:key').cyan
      # END - Facebook
    
      # Twitter
      twitterConfig =
        consumerKey: config.get 'auth:twitter:key'
        consumerSecret: config.get 'auth:twitter:secret'
        callbackURL: "#{baseUrl}/users/auth/twitter/callback"
      passport.use 'twitter-authz',new TwitterStrategy twitterConfig, (token, tokenSecret, profile, done) ->
        # {"provider":"twitter","id":15415595,"username":"martin_sunset","displayName":"Martin Wawrusch","photos":[{"value":"https://si0.twimg.com/profile_images/247413746/People_MartinWawrusch_Small_normal.jpg"}],"_raw":"{\"id\":15415595,\"id_str\":\"15415595\",\"name\":\"Martin Wawrusch\",\"screen_name\":\"martin_sunset\",\"location\":\"West Hollywood\",\"url\":null,\"description\":\"\",\"protected\":false,\"followers_count\":309,\"friends_count\":912,\"listed_count\":7,\"created_at\":\"Sun Jul 13 15:31:38 +0000 2008\",\"favourites_count\":4,\"utc_offset\":-28800,\"time_zone\":\"Pacific Time (US & Canada)\",\"geo_enabled\":false,\"verified\":false,\"statuses_count\":335,\"lang\":\"en\",\"status\":{\"created_at\":\"Wed Nov 07 19:58:39 +0000 2012\",\"id\":266268448957538304,\"id_str\":\"266268448957538304\",\"text\":\"RT @ardenash: @ArdenAshAgency If not elegance, then edge. To begin, wearable technology: http:\\/\\/t.co\\/PyPPoRny\",\"source\":\"web\",\"truncated\":false,\"in_reply_to_status_id\":null,\"in_reply_to_status_id_str\":null,\"in_reply_to_user_id\":null,\"in_reply_to_user_id_str\":null,\"in_reply_to_screen_name\":null,\"geo\":null,\"coordinates\":null,\"place\":null,\"contributors\":null,\"retweeted_status\":{\"created_at\":\"Wed Nov 07 19:57:25 +0000 2012\",\"id\":266268137262039040,\"id_str\":\"266268137262039040\",\"text\":\"@ArdenAshAgency If not elegance, then edge. To begin, wearable technology: http:\\/\\/t.co\\/PyPPoRny\",\"source\":\"web\",\"truncated\":false,\"in_reply_to_status_id\":null,\"in_reply_to_status_id_str\":null,\"in_reply_to_user_id\":358333268,\"in_reply_to_user_id_str\":\"358333268\",\"in_reply_to_screen_name\":\"ArdenAshAgency\",\"geo\":null,\"coordinates\":null,\"place\":null,\"contributors\":null,\"retweet_count\":1,\"favorited\":false,\"retweeted\":false,\"possibly_sensitive\":false},\"retweet_count\":1,\"favorited\":false,\"retweeted\":false,\"possibly_sensitive\":false},\"contributors_enabled\":false,\"is_translator\":false,\"profile_background_color\":\"C0DEED\",\"profile_background_image_url\":\"http:\\/\\/a0.twimg.com\\/images\\/themes\\/theme1\\/bg.png\",\"profile_background_image_url_https\":\"https:\\/\\/si0.twimg.com\\/images\\/themes\\/theme1\\/bg.png\",\"profile_background_tile\":false,\"profile_image_url\":\"http:\\/\\/a0.twimg.com\\/profile_images\\/247413746\\/People_MartinWawrusch_Small_normal.jpg\",\"profile_image_url_https\":\"https:\\/\\/si0.twimg.com\\/profile_images\\/247413746\\/People_MartinWawrusch_Small_normal.jpg\",\"profile_link_color\":\"0084B4\",\"profile_sidebar_border_color\":\"C0DEED\",\"profile_sidebar_fill_color\":\"DDEEF6\",\"profile_text_color\":\"333333\",\"profile_use_background_image\":true,\"default_profile\":true,\"default_profile_image\":false,\"following\":false,\"follow_request_sent\":false,\"notifications\":false}","_json":{"id":15415595,"id_str":"15415595","name":"Martin Wawrusch","screen_name":"martin_sunset","location":"West Hollywood","url":null,"description":"","protected":false,"followers_count":309,"friends_count":912,"listed_count":7,"created_at":"Sun Jul 13 15:31:38 +0000 2008","favourites_count":4,"utc_offset":-28800,"time_zone":"Pacific Time (US & Canada)","geo_enabled":false,"verified":false,"statuses_count":335,"lang":"en","status":{"created_at":"Wed Nov 07 19:58:39 +0000 2012","id":266268448957538300,"id_str":"266268448957538304","text":"RT @ardenash: @ArdenAshAgency If not elegance, then edge. To begin, wearable technology: http://t.co/PyPPoRny","source":"web","truncated":false,"in_reply_to_status_id":null,"in_reply_to_status_id_str":null,"in_reply_to_user_id":null,"in_reply_to_user_id_str":null,"in_reply_to_screen_name":null,"geo":null,"coordinates":null,"place":null,"contributors":null,"retweeted_status":{"created_at":"Wed Nov 07 19:57:25 +0000 2012","id":266268137262039040,"id_str":"266268137262039040","text":"@ArdenAshAgency If not elegance, then edge. To begin, wearable technology: http://t.co/PyPPoRny","source":"web","truncated":false,"in_reply_to_status_id":null,"in_reply_to_status_id_str":null,"in_reply_to_user_id":358333268,"in_reply_to_user_id_str":"358333268","in_reply_to_screen_name":"ArdenAshAgency","geo":null,"coordinates":null,"place":null,"contributors":null,"retweet_count":1,"favorited":false,"retweeted":false,"possibly_sensitive":false},"retweet_count":1,"favorited":false,"retweeted":false,"possibly_sensitive":false},"contributors_enabled":false,"is_translator":false,"profile_background_color":"C0DEED","profile_background_image_url":"http://a0.twimg.com/images/themes/theme1/bg.png","profile_background_image_url_https":"https://si0.twimg.com/images/themes/theme1/bg.png","profile_background_tile":false,"profile_image_url":"http://a0.twimg.com/profile_images/247413746/People_MartinWawrusch_Small_normal.jpg","profile_image_url_https":"https://si0.twimg.com/profile_images/247413746/People_MartinWawrusch_Small_normal.jpg","profile_link_color":"0084B4","profile_sidebar_border_color":"C0DEED","profile_sidebar_fill_color":"DDEEF6","profile_text_color":"333333","profile_use_background_image":true,"default_profile":true,"default_profile_image":false,"following":false,"follow_request_sent":false,"notifications":false}}
        account =
          provider : 'instagram'
          identity : profile.id
          token :  token
          tokenSecret : tokenSecret
          profile: profile
        #console.log "POST LOGIN: #{JSON.stringify(profile)}"
        done(null,account)
    
      postLoginTwitter = (req, res, next) =>
        identityStore.users.postIdentity req.user.id || req.user.actorId, "twitter", req.account.token, req.account.tokenSecret, req.account.profile, (err) =>
          if err
            req.flash "Could not add this identity - please retry in a couple seconds."
            winston.error "Failed to add Twitter: Error #{JSON.stringify(err)}, user: #{JSON.stringify(req.user)}"
          res.redirect "/account/linked"
    
      expressApp.get "/users/auth/twitter", passport.authorize("twitter-authz")
      expressApp.get "/users/auth/twitter/callback", passport.authorize("twitter-authz", failureFlash: true), postLoginTwitter
      winston.info "Registered service provider: " + "Twitter".cyan + " for key: " + config.get('auth:twitter:key').cyan
      # END - Twitter
    */

  };

}).call(this);
