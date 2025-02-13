if 0 {
	This proc doesnt need assumes site context, so _siteSet prior to coming in here
	It also requires a dictionary of threads. The only key it needs is
	`name`

	
	TODO:
	Dont assume all in the same site. Split it into a dictionary key is the site name,
	value is the list of threads, then loop over sites, and bulk get details for those
	threads
	
	Updates:
	04/26/2015 - Assume thread status and alive as down until proven up. This will help
					if the proces is down it will show the thread as down
	05/12/2015 - Return if threadlist is empty
	06/08/2017 - Added DataError and ReplyError values.
}


proc _threadStat {threads} {
	global env
	
	# ensure there are threads
	if {[llength $threads]==0} {
		return $threads
	}
	
	# get the site we are working with
	set Site [dict get [lindex $threads 0] Site]
	
	# get the state of the daemons
	set dStates [_daemonState $Site]
	#echo $dStates
	
	# get a list of just the thread names, to get mass stats
	set threadList ""
	foreach thread $threads {
		lappend threadList [dict get $thread Name]
	}
	
	# If the daemons are up, get the thread stats
	set allResults ""
	set allResultsKeys ""
	if {[dict get $dStates lock] && [dict get $dStates monitor]} {
	#	echo $Site
	#	echo hcicmd -s $Site -t d -c \"statusrpt \{$threadList\}\"
	
	    # Frequently a site will throw up if the monitor deamon was having issue
	    # This code will email out (via echo in cron)
	    # But then try to remedey the sitation by stopping and starting the daemons
    	set output ""
    	set err ""
    	set herr [catch {
    		set allResults [exec ksh -c "hcicmd -s $Site -t d -c \"statusrpt \{$threadList\}\""]
    	} output err]
    	
    	if {$herr==1} {
    	    echo Trying to gather stats from $Site failed!
    	    echo Error: [dict get "-errorinfo" $err]
    	    echo
    	    echo Command: hcicmd -s $Site -t d -c \"statusrpt \{$threadList\}\"
    	    catch {_daemonAction $Site stop}
		    catch {_daemonAction $Site start}
    	}
    	
		set allResults [lrange $allResults 2 end]
		
		set allResultsKeys [keylkeys allResults]
	}

	
	# per thread takes 11 seconds
	set idx -1
    foreach thread $threads {
		
		# Get name from dictionary
		set Name [dict get $thread Name]
		set Site [dict get $thread Site]
		set Process [dict get $thread Process]
		
		# Get stats
		#set result [msiGetStatSample $Name]
		#set result [exec ksh -c "hcicmd -p $Process -s $Site -t d -c \"statusrpt $Name\""]
		#set result [lindex $result 2 end]
		
		set result ""
		set StatKEYS ""
		if {[lsearch -exact $allResultsKeys "$Name"] != -1} {
			set result [keylget allResults $Name]
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
		
		set MsgIn "0"
		if {[lsearch -exact $StatKEYS "MSGSIN"] != -1} {					;#Is there anything pending
			set MsgIn [keylget result MSGSIN]
		}
		dict append thread MsgIn $MsgIn
		
		set MsgOut "0"
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
		
		set DataError 0
		if {[lsearch -exact $StatKEYS "ERRORCNT"] != -1} {
		    set DataError [expr $DataError + [keylget result ERRORCNT]]
		}
		dict append thread DataError $DataError
		
		dict append thread ReplyError 0
		
		# Overwrite thread 
		lset threads [incr idx] $thread
	}
	
	
	
	return $threads
}
##Handle command line
#if {$argc>0} {
#	
#	set ScriptName $argv0
#	set ScriptDir [join [lrange [split [string map {\\ /} $ScriptName] "/"] 0 end-1] "/"]
#echo $ScriptDir
#	# cd to script location
#	cd "$ScriptDir/../"
#	
#	return _threadStat
#}
