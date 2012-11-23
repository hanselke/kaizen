REBOL [
	Title: "App specific test env setup and API helpers"
	Date: 2012-01-17
	Author: onetom@openbusiness.com.sg
]

do %lib/malako/malako.r
do %lib/malako/assert.r
api-server: http://127.0.0.1:8001/
log-net: func[s][]
reg-payload: func[role] [ role: to-string role
	context [
		email: rejoin [role "@ob.sg.com"]
		password: password2: copy/part role 1
		company_name: ""
		roles: reduce [role]
	]
]
login-payload: func[role] [ role: to-string role
	context [
		email: rejoin [role "@ob.sg.com"]
		password: copy/part role 1
	]
]
do reset_http_client: does [
	sessions: copy []
	current-role: none
]
current-session: does [select sessions current-role]
set-current-session: func[s] [
	if none? current-role [return none]
	either found? find sessions current-role
		[sessions/:current-role: s]
		[repend sessions [current-role s]]
]
as: func ['a 'role [word!]] [ current-role: role ]
send: func	['resource [word! path!]] [ post :resource none ]
register: func['role] [ post users reg-payload role ]
login: func['role] [ as a :role post login login-payload role ]
