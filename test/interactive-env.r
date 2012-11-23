REBOL [
	Title: "Setup malako for interactive usage"
	Date: 2012-01-17
	Author: onetom@openbusiness.com.sg
]
do %lib/malako/malako.r
do %lib/malako/assert.r
api-server: http://127.0.0.1:8001/
current-session: ""
set-current-session: func[s] [current-session: s]
do login: func[cred] [
	unless block? cred [cred: [onetom@openbusiness.com.sg x]]
	post login compose
		[ email: (mold cred/1) password: (mold cred/2) ]
] 'me