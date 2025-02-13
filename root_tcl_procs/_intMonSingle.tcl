if 0 {
	Name:
	_intMonSingle.tcl

	Desc:
	We want to update just a single record

	Param:
	thread - standard thread dictionary as seen in $HCIROOT/cache/threads.details.txt

	Header Contruct:
	HDR,$SITE,$GENERATED,$ENGINE
	HDR,,04/23/2015 09:00:01,QDX

	Thread Contruct:
	$THEAD,$STATUS,$PENDING,$LASTREAD,$LASTWRITE,$DATAERROR,$REPLYERROR
	,Up,0,04/23/2015 08:59:59,04/23/2015 08:59:59,0,0

	TODO:
	1. Instead of ftp call rest service

	Change Log:
	2017-10-05 - TMH
	-Added support for multiple threads
	2017-10-09 - TMH
	-Bail if you are on a test server
}

proc _intMonSingle {args} {

	if {[_isNonProd]} {
		return
	}
	#echo $args
	#echo [_dictGet {*}$args Site]

	# Suppport old models where they sent in a dictionary
	# instead of a list of dict
	if {[_dictGet {*}$args Site]!=""} {
		set args [list $args]
	}

	#Needed vars
	global env
	set HCIROOT $env(HCIROOT)
	set now [clock format [clock seconds] -format "%m/%d/%Y %H:%M:%S"]
	set cSec [clock seconds]                                                    ;#Current second (epoch time)
	set rand [expr { rand() }]

	#Start the output
	set output ""


	# Expect going forward the engine name in roger mon to match exactly the server name
	set header [string toupper [_serverName]]
	if {[_serverNum]=="01"} {
		set header "[string toupper [_serverType]]"
	}
	if {[_serverNum]=="02"} {
		set header "[string toupper [_serverType]2]"
	}


	foreach thread {*}$args {

		#Get thread details
		set Site [dict get $thread Site]
		set Name [dict get $thread Name]
		set Status [dict get $thread Status]
		set LastWrite [dict get $thread LastWrite]
		set LastRead [dict get $thread LastRead]
		set Pending [dict get $thread Pending]
		set DataError  [dict get $thread DataError]
		set ReplyError  [dict get $thread ReplyError]

		lappend output [join [list HDR $Site $now $header] ,]
		lappend output [join [list $Name $Status $Pending $LastRead $LastWrite $DataError $ReplyError] ,]
	}


	#Ftp to momentum
	_FTP [dict create \
		suffix .$cSec$rand.txt \
		echo true \
		put [list \
			[dict create \
			content [join $output \r\n] \
			type data \
			name ""
		]
		]
		]
	}