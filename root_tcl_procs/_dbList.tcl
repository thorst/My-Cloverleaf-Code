proc _dbList {site db {options ""}} {

	#define states
	set states [dict create \
		1 "On IB pre-TPS queue" \
		2 "On IB post-TPS queue" \
		3 "Sent via ICL to Xlate" \
		4 "Staged at ICL receive by Xlate" \
		5 "On pre-Xlate queue" \
		6 "Currently in Xlate processing" \
		7 "On post-Xlate queue" \
		8 "Sent via ICL to destination" \
		9 "Staged at ICL recv by destination" \
		10 "On OB pre-tps queue" \
		11 "On OB post-tps queue" \
		12 "On FWD pre-TPS queue" \
		13 "On FWD post-TPS queue" \
		14 "Successful delivery" \
		15 "Failed delivery" \
		16 "OB reserved for IB reply" \
		19 "On java IB protocol" \
		20 "On java OB protocol" \
		100 "Failed to get trix id" \
		101 "Unsupported trx id" \
		103 "Tcl failure in Trixid determination" \
		104 "No destination for reply" \
		105 "No destination for message" \
		106 "Disallowed Gateway routing" \
		107 "Incorrect remote icl server" \
		200 "Failure in IB Reply TPS eval" \
		201 "Failure in IB Data TPS eval" \
		202 "Failure in OB Reply TPS eval" \
		203 "Failure in OB Data TPS eval" \
		204 "Failure in FWD Reply TPS eval" \
		205 "Failure in FWD Data TPS eval" \
		300 "XLT config file unloadable" \
		301 "Internal XPM Tcl failure" \
		302 "Tcl callout error" \
		303 "Tcl callout abort" \
		304 "XPM data fetch failed" \
		305 "XPM data store failed" \
		306 "XPM bilkcopy operation failed" \
		307 "Input data validation failure" \
		308 "Output data validation failure" \
		309 "XPM default value feitch failed" \
		310 "XPM math operation error" \
		311 "\$xlateOutVals unset" \
		312 "XPM numeric comparison error" \
		313 "XPM string comparison error" \
		314 "Xslt transformation failure" \
		400 "Failure in protocol startup" \
		401 "Failure in ACK/NAK proc" \
		402 "Failure in SENDOK proc" \
		403 "Failure in SENDFAIL proc" \
		404 "Failure in REPLYGEN proc" \
		405 "Retry count exceeded" \
		406 "Tcl failure in startup SendOk TPS" \
		407 "Tcl failure in startup SendFail TPS" \
		408 "Tcl failure in protocol driver TPS" \
		409 "Tcl failure in Pre-write TPS" \
		410 "Failed to recover reserved outbound message" \
		414 "User code error in Upoc protocol read TPS" \
		415 "User code error in Upoc protocol write TPS" \
		416 "Inbound encoding conversion error" \
		417 "Outbound encoding conversion error" \
		418 "Unable to deliver to specified server connection" \
		500 "Internal failure: unable to read message data chain" \
		1000 "Internal failure: start route" \
		1001 "Internal failure: bad route config" \
		1002 "Internal failure: no route config" \
		1003 "Internal failure: bad route detail" \
		1004 "Internal failure: bad format" \
	]

set classes [dict create \
	P Protocol \
	E Engine
]

set types [dict create \
	D Data \
	R Reply
]

set fwds [dict create \
	N N
]

#get context
#	echo [_siteSet $site]
#	echo [exec showroot]


# get the state of the daemons
set dStates [_daemonState $site]

#Build command
set command "hcidbdump -$db -l"
set TO [_dictGet $options TO]

if {$TO!= ""} {
	append command " -d $TO"
}
set FR [_dictGet $options FR]
if {$FR!= ""} {
	append command " -f $FR"
}


#get list
set output ""
if {[dict get $dStates lock] && [dict get $dStates monitor]} {
	set output [exec ksh -c "$command"]
}
#echo $output
set lines [split $output "\n"]
set records ""
for {set x 8} {$x<[expr [llength $lines]-2]} {incr x 8} {
	set dateLine [lindex $lines $x];#lol
	set main [lindex $lines [expr $x+1]]
	set dest [lindex $lines [expr $x+2]]

	set date "$dateLine [string range $main 0 8]"
	set date [string trim $date]

	set size [string trim [string range $main 41 47]]

	set source [string range $main 48 end]
	set source [string trim $source]

	#set id [lindex [split [string trim [string range $main 8 23] " \[\]"] "."] end]
	set id [string trim [string range $main 8 23] " \[\]"]
	set dest [string trim $dest]
	set state [string trim [string range $main 35 40]]

	#Get state description
	set stateDesc "$state - Unknown error - look it up in cl db tool"
	if {[dict exists $states $state]} {
		set stateDesc "$state - [dict get $states $state]"
	}

	set class [string range $main 24 24]
	set type [string range $main 26 26]

	lappend records [dict create \
		date $date \
		id $id \
		source $source \
		dest $dest \
		state $state \
		stateDesc $stateDesc \
		type [dict get $types $type] \
		class [dict get $classes $class] \
		size $size
	]
}
return $records
}
#echo [_dbList  e]


