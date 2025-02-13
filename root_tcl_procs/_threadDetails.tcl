if 0 {
    Used in the bouncer page
    Used in the import locations feature on the interface page
    Used in _archiveSmat.tcl
}


proc _threadDetails {} {
	

	global env
	set HCIROOT $env(HCIROOT)
	
	# Start the timer
	set TIME_start [clock clicks -milliseconds]

	# Get the sites
	set sites [_siteList]
	set HCIROOT $env(HCIROOT)

	# For each site get a thread and thier details
	set threadDict ""
	foreach site $sites {
		set SiteDir [file join $env(HCIROOT) $site]
		set nc "$SiteDir/NetConfig"
		
		# Set site to destination
		#echo $site
		#_siteSet $site
		#echo [exec showroot]
		
		# Get a dict of threads with other information from net config
		set threads [_threadList $site]
		
		# Get a dict of threads with stat information
		#Commeted out due to global monitor
		#set threads [_threadStat $threads]
		

		# Add the error database
		#Commeted out due to global monitor
		#set threads [_threadErrors $site $threads]
		
		# Add the inbound dir pending
		
		# Add the route pending
		
		# Add this list of threads to the existing list
		set threadDict [concat $threadDict $threads]
	}

	# Compile to huddle
	set threadList [jCompile {list {dict DataError number Alive bool ReplyError number MsgOut number MsgIn number Pending number * string}} $threadDict]

	# Stop timer
	set TIME_taken [expr [clock clicks -milliseconds] - $TIME_start]

	# Define the average file and default to what just ran
	set avg $TIME_taken
	set cacheAvg "$HCIROOT/cache/threads.avg.txt"

	# Get the real average if file existed
	if {[file exist $cacheAvg]} {
		set fl [open $cacheAvg]
		set avg [read $fl]
		if {[catch {close $fl} err]} {
			puts "ls command failed: $err"
		}
	}

	# Get the new average
	set avg [expr ($avg+$TIME_taken)/2]

	# Save the average
	set fl [open $cacheAvg w]
	puts $fl $avg
	if {[catch {close $fl} err]} {
		puts "ls command failed: $err"
	}


	# Save to cache
	set cacheDetails "$HCIROOT/cache/threads.details.txt"
	set cache [open $cacheDetails w]
	puts $cache [jRender [jObject \
					successful [jTrue] \
					error "" \
					totalthreads [jNum [llength $threadDict]] \
					totalsites [jNum [llength $sites]] \
					cached [clock format [clock seconds] -format "%m/%d/%Y %H:%M:%S"] \
					executionMS $TIME_taken \
					executionAvgMS $avg \
					threads $threadList
				]]
	#
	if {[catch {close $cache} err]} {
		puts "ls command failed: $err"
	}



}

