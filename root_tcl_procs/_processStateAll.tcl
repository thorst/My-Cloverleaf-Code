if 0 {
	Name
		_processStateAll
	
	Purpose
		Get the state of all processes
		in all sites
	
	Returns
		* running
		* dead
	
	Exec
		hcicmd -t d -s $site -c "psummary $process"
		>> psummary {helloworld running {Started at Fri Feb 27 14:05:10 2015}}
		>> psummary {helloworld dead {Normal exit at Tue Mar 10 13:07:16 2015}}
	
	Change Log
	    09/20/2017 - TMH
	        -Now process state takes multiple sites so sicne i was getting them all to begin with
	            I no longer need to loop over them and waste exec calls
        10/21/2017 - TMH
            -New sites or unused sites may not have any processes, this would error out
}
proc _processStateAll {} {
    # Predfine the list of states and then get a list of sites
	set allState ""
	set sites [_siteList]
	
	foreach site $sites {
	
		# Get all the processes for site and thier respective states
		set processes [_processList $site]
		if {[llength $processes]==0} {continue;}
		set states [_processState $site $processes]
		
		# Append to list, the dictionary for this process/site pair
		foreach process $processes state $states {
			lappend allState [dict create \
					site $site \
					process $process \
					state $state]
		}
	}
	
	# Return the list of processes
	return $allState
}