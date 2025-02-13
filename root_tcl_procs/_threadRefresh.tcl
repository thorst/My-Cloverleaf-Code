if 0 {
	We want to allow ops to refresh the stats of a specific thread, before the 2 minutes
	increment. This is particularly useful because _threadAction overwrites the cache with the
	current status. This frequently is opening because it takes longer than a couple seconds to
	connect to the other side.
}


proc _threadRefresh {site process thread} {
	global env
	
	
	
	# get the state of the daemons
	set dStates [_daemonState $Site]

	
	
	# If the daemons are up, get the thread stats
	set result ""
	set StatKEYS ""
	if {[dict get $dStates lock] && [dict get $dStates monitor]} {
		# Get the status
		#set result [msiGetStatSample $thread]
		set result [exec ksh -c "hcicmd -p $process -s $site -t d -c \"statusrpt $thread\""]
		set result [lindex $result 2 end]
		set StatKEYS [keylkeys result]
	}


	# Protocal Status (UP/DOWN/CONNECTING)
	set Status "Down"
	if {[lsearch -exact $StatKEYS "PSTATUS"] != -1} {
		set Status [string totitle [keylget result PSTATUS]]
	}
	dict append thread Status $Status
	
	set Alive false
	if {[lsearch -exact $StatKEYS "ALIVE"] != -1} {
		set Alive [string totitle [keylget result ALIVE]]
	}
	if {$Alive==1} {set Alive true;} else {set Alive false;}
	dict append thread Alive $Alive
	
	set Pending 0
	if {[lsearch -exact $StatKEYS "OBDATAQD"] != -1} {					;#Is there anything pending
		set Pending [expr $Pending + [keylget result OBDATAQD]]
	}
	dict append thread Pending $Pending
	
	set MsgIn ""
	if {[lsearch -exact $StatKEYS "MSGSIN"] != -1} {					;#Is there anything pending
		set MsgIn [keylget result MSGSIN]
	}
	dict append thread MsgIn $MsgIn
	
	set MsgOut ""
	if {[lsearch -exact $StatKEYS "MSGSOUT"] != -1} {					;#Is there anything pending
		set MsgOut [keylget result MSGSOUT]
	}
	dict append thread MsgOut $MsgOut
	
	set LastWrite "Never"
	if {[lsearch -exact $StatKEYS "PLASTWRITE"] != -1 && [keylget result PLASTWRITE]!=0} {	;				
		set LastWrite [clock format [keylget result PLASTWRITE] -format "%m/%d/%Y %H:%M:%S"]
	}
	dict append thread LastWrite $LastWrite
	
	set LastRead "Never"
	if {[lsearch -exact $StatKEYS "PLASTREAD"] != -1 && [keylget result PLASTREAD]!=0} {    					
		set LastRead [clock format [keylget result PLASTREAD] -format "%m/%d/%Y %H:%M:%S"]
	}
	dict append thread LastRead $LastRead
	
	
	# Overwrite thread 
	lset threads [incr idx] $thread
	
	
	#over write the cache file
	set no [_threadOverwriteCache $site $process $thread $thread]

	
	#Trigger update for intmon
	_intMonSingle $no
	
	return $no
}