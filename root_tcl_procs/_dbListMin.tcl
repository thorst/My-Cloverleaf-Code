if 0 {
	Given a site and "e" or "r" for the db it will return
	a dictionary of threads with thier respective error counts
	
	Playground;
	echo [_dbListMin physician1 e]
}
proc _dbListMin {site db} {
	#Use regular dbList
	set db [_dbList $site $db]
	
	# get globals
	global env
	set HCISITEDIR $env(HCISITEDIR)
	
	# get site
	set site [lindex [file split $HCISITEDIR] end]
	
	# get errors
	set records [_dbList $site e]
	
	# build dictionary
	set grouped ""
	foreach err $records {
		
		#pull data from dictionary
		set dest [dict get $err dest]
		set source [dict get $err source]
		set type [dict get $err type]
		
		#determine thread to put it on
		set lookFor $dest
		if {$dest=="" || [llength $dest]>1} {
			set lookFor $source
		}
		
		# ensure its in the dictionary
		if {[dict exists $grouped $lookFor]==0} {
			dict set grouped $lookFor [dict create Reply 0 Data 0]
		}
		
		#increment the count
		set exists [dict get $grouped $lookFor]
		if {$type=="Data"} {
			dict incr exists Data
		} else {
			dict incr exists Reply
		}
		
		#update the count for this thread
		dict set grouped $lookFor $exists;#[join $count ","]
	}
	
	return $grouped
}