if 0 {
    _dbFullDetails
        Grab a specific message from the database, optionally delete
        
    Change Log:
        09/06/2017 - tmh
            -Added delete option, had to wrap in ksh in order to execute
}
proc _dbFullDetails {site db messageId {delete false}} {

	#get context
	_siteSet $site
	
	#get list
	#hcidbdump -e -L -m 605048:605048
	set cmd ""
	if {$delete} {
	    set cmd "-D -F"
	}
	set output [exec ksh -c "hcidbdump -$db $cmd -L -m $messageId:$messageId"]
	set lines [split $output "\n"]
	
	set strmessage "    message           : *"
	set message [lsearch -inline $lines $strmessage]
	set message [string range $message [string length $strmessage] end-1]
	set message [string map {"\r" "\r" "\n" "\n" "\\x0d" "\r"} $message]

	return [dict create \
		message $message		
	]
}
#_dbFullDetails physician e 605048