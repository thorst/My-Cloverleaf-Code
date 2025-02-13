if 0 {
	Name
		_processStateAll
	
	Purpose
		Get the state of a given process in site
	
	Returns
		* running
		* dead
	
	Exec
		hcicmd -t d -s $site -c "psummary $process"
		>> psummary {helloworld running {Started at Fri Feb 27 14:05:10 2015}}
		>> psummary {helloworld dead {Normal exit at Tue Mar 10 13:07:16 2015}}
	
	Exec Count
		1
	
	Change Log
	    09/20/2017 - TMH
	        -changed from process to args to allow to send multiple process in and get thier states in order they were sent
	        -changed concept from allowing errors to bubble up to catching. This occures if the daemons are down. Now it will
	            return a state of unknown. Technically they could still be up even with daemons being down, we just cant retrieve
	            that info until the daemons are running.
        12/11/2018 - TMH
            -changes to support windows
}
proc _processState {site args} {
global env tcl_platform
# Get the platform
	set Platform $tcl_platform(platform)
	
    # Convert passed list to a string
    set processes {*}$args
    
    # Attempt to get statuses
    set procState ""
    
    if {$Platform=="windows"} {
	catch {set procState [exec cmd /C hcicmd -t d -s $site -c "psummary $processes"]}
    } else {
    catch {set procState [exec hcicmd -t d -s $site -c "psummary $processes"]}
    }
	
	# If getting status failed, most likely due to down daemon, return unknown for each process parametered
	if {$procState ==""} {
	    return [lrepeat [llength $processes] "unknown"]
	}
	
	# Parse the returned output
	set procState [lrange $procState 2 end]
	set states ""
	foreach p $procState {
	    lappend states [lindex $p 1]
	}
	
	# Return a list of states based on order they were sent in
	return $states
}