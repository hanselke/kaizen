var fs = require('fs');
var sys = require('sys');
var connect = require('express');
var Store = connect.session.Store;

var FileStore = module.exports = function FileStore(options) {
	options = options || {};
	this.storeFilename = options.storeFilename || './sessions.json';
	this.sessions = {};
	this.loadSessions();
};
FileStore.prototype.__proto__ = Store.prototype;

exports.FileStore = FileStore;

FileStore.prototype.loadSessions = function() {
	try { 
		var data = fs.readFileSync(this.storeFilename);
		this.sessions = JSON.parse(data);
	} catch (e) {
		this.sessions = {};
	}
}

FileStore.prototype.storeSessions = function() {
	fs.writeFileSync(this.storeFilename+".tmp", JSON.stringify(this.sessions));
	fs.renameSync(this.storeFilename+".tmp", this.storeFilename);
}

FileStore.prototype.get = function(sid, fn){
	if (sid in this.sessions) {
		fn(null, JSON.parse(this.sessions[sid]));
	} else {
		fn();
	}
};

FileStore.prototype.set = function(sid, sess, fn){
	this.sessions[sid] = JSON.stringify(sess);
	this.storeSessions();
	process.nextTick(function() {
		fn && fn();
	});
};

FileStore.prototype.destroy = function(sid, fn){
	delete this.sessions[sid];
	this.storeSessions();
	fn && fn();
};

FileStore.prototype.all = function(fn){
	var arr = [];
	var keys = Object.keys(this.sessions);
	for (var i = 0, len = keys.length; i < len; ++i) {
		arr.push(this.sessions[keys[i]]);
	}
	fn(null, arr);
};


FileStore.prototype.clear = function(fn){
	this.sessions = {};
	this.storeSessions();
	fn && fn();
};

FileStore.prototype.length = function(fn){
	fn(null, Object.keys(this.sessions).length);
};
