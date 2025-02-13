if 0 {
	test
}

proc _threadList {site {includeRoutes false}} {
	global env

	# Get this sites directory/ netconfig
	set SiteDir [file join $env(HCIROOT) $site]
    set nc "$SiteDir/NetConfig"
	netcfgLoad $nc													;#Load net config
	
	# Read net config
	set fl [open $nc]										
    set data [split [read $fl] \n]							
    close $fl												
	
	# Get a list of the protocols
    set threads ""										
    foreach line [lsearch -all -inline $data "protocol * \{"] {									
			lappend threads [dict create Name [lindex [split $line " "] 1]]
    }
	
	# For each one, get additional data
	set idx -1
	foreach thread $threads {
		set connData [netcfgGetConnData [dict get $thread Name]]					;#Get thread data, needed for fileset local get pending in dir
		set ConnKeys [keylkeys connData]
		set protData [keylget connData PROTOCOL]
		set protKeys [keylkeys protData]
		set SAVEMSGSData [keylget connData SAVEMSGS]
		set SAVEMSGSKeys [keylkeys SAVEMSGSData]
		set smsData [keylget connData SMS]
		#set smsKeys [keylkeys smsData]
		set xlateData [keylget connData DATAXLATE]
		#set xlateKeys [keylkeys xlateData]
		
		# Protocol site name
		dict append thread Site $site
		
		# Add Type Literal
		dict append thread Type "protocol"
		
		# Protocol process name
		if {[lsearch -exact $ConnKeys "PROCESSNAME"] != -1} {  					;#Is there pstatus (up, down, connecting)
			#set thread [dict merge $thread [dict create Process [keylget connData PROCESSNAME]]]
			dict append thread Process [keylget connData PROCESSNAME]
		}
		
		# See if its protocol is fileset local or tcp/ip
		dict append thread IbDir [_keylget protData IBDIR]
		
		# Get host and port. If inter-site, grab different port key name
		set HOST ""
		set PORT ""
		if {[lsearch -exact $protKeys "HOST"] != -1} {  					
			set HOST [keylget protData HOST]
			set PORT [keylget protData PORT]
		} elseif {[lsearch -exact $ConnKeys "ICLSERVERPORT"] != -1} {
            set PORT [_keylget connData ICLSERVERPORT]
        }
        
		#set thread [dict merge $thread [dict create IbDir $IbDir]]
		dict append thread HOST $HOST
		dict append thread PORT $PORT
		
		# Smat in and out =================================================
		set INFILE ""
		if {[_keylget SAVEMSGSData INSAVE]==1} {
			set INFILE [_keylget SAVEMSGSData INFILE]
		}
		#set thread [dict merge $thread [dict create IbDir $IbDir]]
		dict append thread SmatIn $INFILE
		
		set OUTFILE ""
		if {[_keylget SAVEMSGSData OUTSAVE]==1} {
			set OUTFILE [_keylget SAVEMSGSData OUTFILE]
		}
		#set thread [dict merge $thread [dict create IbDir $IbDir]]
		dict append thread SmatOut $OUTFILE
		
		
		# IB and OB TPS =================================================
		set IN_DATA [keylget smsData IN_DATA]
		set IBProc  [keylget IN_DATA PROCS]
		set IBArg  [keylget IN_DATA ARGS]
		set IBEnabled [_keylget IN_DATA PROCSCONTROL]
		
		set OUT_DATA [keylget smsData OUT_DATA]
		set OBProc  [keylget OUT_DATA PROCS]
		set OBArg  [keylget OUT_DATA ARGS]
		set OBEnabled [_keylget OUT_DATA PROCSCONTROL]
		
		
		
		set IBProcs ""
		foreach script $IBProc arg $IBArg en $IBEnabled {
			if {$en == "ENABLED" || $en == ""} {
				set en true
			} else {
				set en false
			}
			lappend IBProcs [dict create name $script \
							  args $arg \
							  enabled $en
			]
		}
		
		set OBProcs ""
		foreach script $OBProc arg $OBArg en $OBEnabled {
			if {$en == "ENABLED" || $en == ""} {
				set en true
			} else {
				set en false
			}
			lappend OBProcs [dict create name $script \
							  args $arg \
							  enabled $en
			]
		}
						
		dict append thread IBProc $IBProcs
		dict append thread OBProc $OBProcs
		
		
		# Routes =================================================
		if {$includeRoutes} {
			set routes ""
			foreach x $xlateData {
				
				set xKeys [keylkeys x]
				
				set enabled [_keylget x ROUTE_ENABLED]
				if {$enabled=="" || $enabled ==1} { set enabled true; } else { set enabled false;}
				
				set TRXID [_keylget x TRXID]
				set ROUTE_DETAILS [keylget x ROUTE_DETAILS]
				set Details ""
				foreach r $ROUTE_DETAILS {
					
					set rKeys [keylkeys r]
					set dest ""
					if {[lsearch -exact $rKeys "DEST"] != -1} {  
						set dest [keylget r DEST]
					}
					
					set proclist ""
					if {[lsearch -exact $rKeys "PROCS"] != -1} {  
						set procsObj [keylget r PROCS]
						
						set procs [_keylget procsObj PROCS]
						set args [_keylget procsObj ARGS]
						set PROCSCONTROL [_keylget procsObj PROCSCONTROL]
						
						foreach script $procs arg $args en $PROCSCONTROL {
							if {$en == "ENABLED" || $en == ""} {
								set en true
							} else {
								set en false
							}
							lappend proclist [dict create name $script \
											  args $arg \
											  enabled $en
							]
						}
					}
					
					# Get if its enabled
					set DETAILS_ENABLED [_keylget r DETAILS_ENABLED]
					if {$DETAILS_ENABLED=="" || $DETAILS_ENABLED ==1} { set DETAILS_ENABLED true; } else { set DETAILS_ENABLED false;}
					
					# Get type, usually raw
					set type [keylget r TYPE]
					
					set detail ""
					dict append detail dest $dest
					dict append detail type $type
					dict append detail enabled $DETAILS_ENABLED
					dict append detail procs $proclist
					
					lappend Details $detail
				}
				
				set route ""
				dict append route trxid $TRXID
				dict append route enabled $enabled
				dict append route details $Details
								
				lappend routes $route
				
			}
			dict append thread routes $routes
		} else {
			dict append thread routes ""
		}
		
		
		#Overwrite thread 
		lset threads [incr idx] $thread
	}
	
	# Get a list of the destination
    foreach line [lsearch -all -inline $data "destination * \{"] {									
		set destName [lindex [split $line " "] 1]
		set connData [netcfgGetDestData $destName]					;#Get thread data, needed for fileset local get pending in dir

		set destination ""
		dict append destination Name $destName
		dict append destination Site $site
		
		# Add Type Literal
		dict append destination Type "destination"
		
		# Destination process name
		dict append destination Process ""

		# Destination inbound directory
		dict append destination IbDir ""

		dict append destination HOST [_keylget connData HOST]
		dict append destination PORT [_keylget connData PORT]

		dict append destination SmatIn ""
		dict append destination SmatOut ""

		dict append destination IBProc ""
		dict append destination OBProc ""

        dict append destination routes ""

	    lappend threads $destination
    }
	


	return $threads
}


