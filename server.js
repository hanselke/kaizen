var	express = require('express'),
	http = require('http'),
	gzip = require('connect-gzip'),
	FileStore = require('./lib/modules/FileStore'),	// session
	child_process = require('child_process'),
	socketIo = require('socket.io'),
	fs = require('fs'),
	backend = require('./backend'),
	ansi_color = require('ansi-color').set,
	color = require('colors'),
	app = express(),
	base_dir = __dirname,
	database_dir = base_dir + '/non/existant',
	frontend_dir = base_dir

function init_db(req, res) {
	child_process.exec('rm -rf  ' + database_dir, function(error, stdout, stderr) {
		fs.mkdirSync(database_dir, 0755)
		backend.init_db()
		res && res.send({})
	})
	// FIXME session memory should also be deleted
}

function getCurrentUser(req, res, next) {
	req.current_user = req.session && backend.users[req.session.current_user_id]
	next()
}

function andLoggedIn(req, res, next) {
	req.current_user ? next() : next(new Error('Unauthorized'))
}

app.configure('development', function() {
	database_dir = base_dir + '/db-test'
	backend.set_db_dir(database_dir)
	init_db() // FIXME this should be sync, so session should not be initialized
})
app.configure('production', function() {
	database_dir = base_dir + '/db'
	backend.set_db_dir(database_dir)
})

app.configure(function() {
	function pad2(i){ return (i < 10) ? '0' + i : i }
	express.logger.token('short-date', function(req, res){
		var d = new Date()
		return pad2(d.getMonth() + 1) + '.' + pad2(d.getDate()) + ' ' + d.toTimeString().substr(0, 8)
	})
	express.logger.token('user', function(req, res){
		return req.current_user ? req.current_user.name || req.current_user.email : 'No-user'
	})
	express.logger.token('color-status', function(req, res){
		var s = res.statusCode
		var color = 'green'
		if (s >= 500) color = 'red'
		else if (s >= 400) color = 'yellow'
		else if (s >= 300) color = 'cyan'
		return ansi_color(s, color)
	})
	app.use(express.logger({ format: ansi_color('[:short-date] (:remote-addr) [:user]', 'white')+' :method :url - HTTP :color-status - :response-time msec' }))
	app.use(express.bodyParser())
	app.use(express.methodOverride())
	app.use(express.cookieParser())
	app.session_mw = express.session({
		secret: "fgjewopvbcpobvdjkln",
		store: new FileStore( {storeFilename: database_dir + '/sessions.json'} )
	})
	app.use(function(req, res, next) {
		if (req.headers.cookie) app.session_mw(req, res, next); else next()
	})
	app.use(getCurrentUser)
});

app.configure('development', function() {
	//Serve all static files without gzip compression
	app.use(app.router);
	app.use(gzip.gzip())
	app.use(express.static(frontend_dir));
	app.post('/init_db', init_db);
	app.post('/restart', function(req, res) { res.send({}) })
	app.post('/set_role', function(req, res) {
		req.current_user.roles = [req.body.role]
		req.current_user.latest_task = undefined
		backend.current_user(req, res)
	})
	app.get(/\/dev-roles.html/, function(req, res){ res.send(
		'<span ng:repeat="role in roles" ' +
			'ng:click="setRole(role)" ng:class="getRoleClass(role)">' +
		'{{role}}</span>'
	)})
});

app.configure('production', function() {
	app.use(app.router);
	// Serve all javascript files with gzip compression
	app.use(gzip.staticGzip(frontend_dir, {matchType: /javascript/}));
	app.get(/\/dev-roles.html/, function(req, res){ res.send('') })
})

/*
app.error(function(e, req, res, next){
	e.message == 'Unauthorized'
	? res.send({msg: "Unauthorized", status: "error"}, 401)
	: next(e)
})
*/

app.post('/sales', andLoggedIn, backend.create_task)
app.get('/tasks/:idx?', backend.tasks)
app.get('/quotes', backend.quotes)
app.post('/users', backend.create_user)
app.post('/login', app.session_mw, backend.login)
app.post('/logout', backend.logout)
app.get('/current_user', backend.current_user)
app.post('/faxes', backend.create_fax)
app.get('/board', backend.board)
app.get('/bods/:bodid', backend.show_bod)
app.get('/ourselves', backend.ourselves)

function initSocketIo(server) {
var io = socketIo.listen(server)
io.set('log level', 0)

var lines = []
io.sockets.on('connection', function (socket) {
	socket.on('msg', function(data){
		lines.push(data)
		if (lines.length > 100) {
			lines.splice(0, lines.length - 100)
		}
		socket.broadcast.emit('msg', data)
	})
	socket.on('nick', function(data){
		var oldNick = socket.get('nick', function(){
			socket.set('nick', data.nick, function(){
/*				if (!oldNick) {
					var d = { time: new Date(), msg: data.nick+' joined to the chat!' }
					lines.push(d)
					socket.emit('msg', d)
					socket.broadcast.emit('msg', d)
				} else if (oldNick != data.nick) {
					var d = { time: new Date(), msg: oldNick+' is now known as '+data.nick }
					lines.push(d)
					socket.emit('msg', d)
					socket.broadcast.emit('msg', d)
				}*/
			})
		})
	})
  socket.on('lines', function (data) {
    socket.emit('lines', { lines: lines })
  });
});

}

port = 8001;
var server = app.listen(port);
initSocketIo(server);
console.log("\n\n\n\nExpress server listening on port %d in %s mode\n", port, app.settings.env);
