if 0 {
	About
		Allow users to stop/start/restart a processes
		
		Note here is that its a bit async here on process startup. It should
		happen quick enough that the process(s) should say up, but reality is
		that if the db has a lot pending itll take a bit
	
	    Shut down seems to be more synchronous but i have a feeling it would
	    time out
	    
	Sandbox
		catch {_processAction physician CSCIN start}
		catch {_processAction physician CSCIN stop}
		catch {_processAction physician CSCIN restart}
		_processAction helloworld helloworld stop
		_processAction "sandbox" "sandbox1,sandbox2" "stop"
		
	    #Stop all processes in a site
		set site "sandbox"
		set processes [_processList $site]
		_processAction $site [join $processes ","] "stop"
		
	Change Log
    	05/07/2015 Todd Horst
    		-If start cleanup before starting
    		-If stop cleanup after stopping
    		
    	9/22/2017 - Todd Horst
    	    -Added support for multiple proceses, this semi breaks the return because
    	        it used to return the status for one and now it returns a list of statuses
    	   -To simplyfiy things im now only doing clean on stops   
    	   -Removed loop check because it wasnt really adding any value. It simply
    	        would loop until it was unhappy. In otherwords if we brought it back it
    	        should do something like try again.
    	    -Added restart option, not just stop/start
	
	Dependencies
		_siteSet
		_processState 1 exec
	
	Exec Count
		3 if starting and process is down
		1 always
		2 if stopping
	
	Total Exec
		4-5
		
	Console Commands
	    hcienginerun/hcienginestop/hcienginerestart -p $process
	        
}
proc _processAction {site process action {force false}} {
	# Initialize
	global env
	set HCIROOT $env(HCIROOT)
	set processes [split $process ","]
	
	# Ensure correct context
	_siteSet $site
	
	# Define command
	set cmd "hcienginerun"
	set desired "running"
	if {$action=="stop"} {
		set cmd "hcienginestop"
		set desired "dead"
	} elseif {$action=="restart"} {
	    set cmd "hcienginerestart -d 30"
	}
	
	# Execute the command (Start/stop) synchronously
	set output [exec ksh -c "$cmd -p $process"]
	
	# If they wanted to stop, perform cleanup
	if {$action=="stop"} {
    	foreach p $processes {
    	    _processClean $site $p $force
    	}
	}
	
	#Get the current state of the process(es)
	return [_processState $site $processes]
}