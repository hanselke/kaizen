// Generated by CoffeeScript 1.4.0
(function() {
  var RoutesAdminUsers, async, errors, sampleUsers, winston, _,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  _ = require('underscore');

  async = require('async');

  winston = require('winston');

  errors = require('some-errors');

  sampleUsers = {
    "andras@openbusiness.com.sg": {
      company_name: "X",
      password: "aaa",
      roles: ["backoffice", "sales", "purchasing"],
      name: "Andras",
      username: "psmith",
      primaryEmail: "andras@openbusiness.com.sg"
    },
    "noroles@openbusiness.com.sg": {
      company_name: "GUAN-HUAT",
      password: "xxx",
      username: 'noroles',
      primaryEmail: "noroles@openbusiness.com.sg"
    },
    "sales@openbusiness.com.sg": {
      company_name: "GUAN-HUAT",
      password: "sales",
      roles: ["sales"],
      username: "sales",
      primaryEmail: "sales@openbusiness.com.sg"
    },
    "hanselke@openbusiness.com.sg": {
      company_name: "openbiz",
      password: "demo",
      roles: ["backoffice", "sales", "purchasing"],
      name: "Hansel Ke",
      username: "hansel",
      primaryEmail: "hanselke@openbusiness.com.sg"
    },
    "onetom@openbusiness.com.sg": {
      company_name: "Open Business",
      password: "xxx",
      roles: ["backoffice", "sales", "purchasing"],
      name: "Tom",
      username: "onetom",
      primaryEmail: "onetom@openbusiness.com.sg"
    }
  };

  module.exports = RoutesAdminUsers = (function() {

    function RoutesAdminUsers(settings) {
      this.syncToBonita = __bind(this.syncToBonita, this);

      this.setupDemoUsers = __bind(this.setupDemoUsers, this);

      this.addUserSync = __bind(this.addUserSync, this);

      this.addRolesToUser = __bind(this.addRolesToUser, this);

      this._addRolesToBonita = __bind(this._addRolesToBonita, this);

      this.setupRoutes = __bind(this.setupRoutes, this);

      this.setupLocals = __bind(this.setupLocals, this);
      _.extend(this, settings);
      if (!this.app) {
        throw new Error("app parameter is required");
      }
      if (!this.identityStore) {
        throw new Error("identityStore parameter is required");
      }
      if (!this.bonitaClient) {
        throw new Error("bonitaClient parameter is required");
      }
    }

    RoutesAdminUsers.prototype.setupLocals = function() {};

    RoutesAdminUsers.prototype.setupRoutes = function() {
      this.app.post('/admin/users/setup-demo', this.setupDemoUsers);
      this.app.post('/admin/users/sync-to-bonita', this.syncToBonita);
      this.app.post('/admin/users/add-user-sync', this.addUserSync);
      return this.app.post('/admin/users/:username/roles', this.addRolesToUser);
    };

    RoutesAdminUsers.prototype._addRolesToBonita = function(username, roles, cb) {
      var addRole,
        _this = this;
      if (roles == null) {
        roles = [];
      }
      if (!(roles.length > 0)) {
        return cb(null);
      }
      addRole = function(role, cb) {
        winston.info("Adding role " + role + " to " + username);
        return _this.bonitaClient.identity.addRoleToUser(username, role, "admin", {}, function(err) {
          if (err) {
            winston.error("Failed adding role " + role + " to " + username + " - Check if role exists");
          }
          return cb(null);
        });
      };
      return async.forEach(roles, addRole, cb);
    };

    /*
      Adding roles to a user
      curl -X POST -d '{"roles" :["admin","user","test"]}' -H 'Content-Type: application/json' -H 'Accept: application/json' http://127.0.0.1:8001/admin/users/mw1/roles
    */


    RoutesAdminUsers.prototype.addRolesToUser = function(req, res, next) {
      var username,
        _this = this;
      username = req.params.username;
      if (!(req.body.roles && req.body.roles.length > 0)) {
        return next(new errors.UnprocessableEntity("roles"));
      }
      return this.identityStore.users.getByName(username, function(err, user) {
        if (err) {
          return next(err);
        }
        if (!user._id) {
          return next(new errors.NotFound("/users/" + username));
        }
        return _this.identityStore.users.addRoles(user._id, req.body.roles, function(err) {
          if (err) {
            return next(err);
          }
          return _this._addRolesToBonita(username, req.body.roles, function(err) {
            return res.json({});
          });
        });
      });
    };

    /*
      Add a user to passport and bonita
      curl -X POST -d '{"username" : "mw9", "password": "testabc", "primaryEmail": "mw9@test.com","roles" : ["admin","sales","purchasing"]}' -H 'Content-Type: application/json' -H 'Accept: application/json' http://127.0.0.1:8001/admin/users/add-user-sync
    */


    RoutesAdminUsers.prototype.addUserSync = function(req, res, next) {
      var _this = this;
      if (!req.body.username) {
        return next(new errors.UnprocessableEntity("username"));
      }
      if (!req.body.password) {
        return next(new errors.UnprocessableEntity("password"));
      }
      if (!req.body.roles) {
        req.body.roles = [];
      }
      return this.identityStore.users.create(req.body, function(err, user) {
        if (err) {
          return next(err);
        }
        return _this.bonitaClient.identity.addUser(req.body.username, req.body.password, "admin", null, function(err, u) {
          if (err) {
            return next(err);
          }
          return _this._addRolesToBonita(req.body.username, req.body.roles, function(err) {
            return res.json(user);
          });
        });
      });
    };

    /*
      Temporary helper to setup demo users. To do this run this once:
      curl -X POST -d '{}' -H 'Content-Type: application/json' -H 'Accept: application/json' http://127.0.0.1:8001/admin/users/setup-demo
    */


    RoutesAdminUsers.prototype.setupDemoUsers = function(req, res, next) {
      var createUser,
        _this = this;
      createUser = function(user, cb) {
        return _this.identityStore.users.create(user, function(err) {
          return cb(null);
        });
      };
      return async.forEach(_.values(sampleUsers), createUser, function(err) {
        return res.json({});
      });
    };

    /*
      Sync users into bonita
      curl -X POST -d '{}' -H 'Content-Type: application/json' -H 'Accept: application/json' http://127.0.0.1:8001/admin/users/sync-to-bonita
    */


    RoutesAdminUsers.prototype.syncToBonita = function(req, res, next) {
      var _this = this;
      return this.identityStore.users.all(0, 100, function(err, result) {
        var createUserInBonita, handleRoles, items;
        if (err) {
          winston.error(JSON.stringify(err));
        }
        if (err) {
          return next(err);
        }
        items = result.items;
        createUserInBonita = function(user, cb) {
          return _this.bonitaClient.identity.addUser(user.username, "test1234", "admin", null, function(err, u) {
            return cb(null);
          });
        };
        handleRoles = function(user, cb) {
          return _this._addRolesToBonita(user.username, user.roles, function(err) {
            return cb(null);
          });
        };
        return async.forEach(items || [], createUserInBonita, function(err) {
          return async.forEach(items || [], handleRoles, function(err) {
            return res.json({});
          });
        });
      });
    };

    return RoutesAdminUsers;

  })();

}).call(this);
