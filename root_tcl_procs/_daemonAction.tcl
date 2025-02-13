if 0 {
    Name
    _daemonAction site action ?what? ?force?
    
        * what  - Default: "l,m" - is a comma seperated list of daemons to act upon
        * force - Default: false - determines whether to PS kill any errant processes
    
    About
        Stop or start a sites daemons. Depending on your command (stop lock) it will also
        issue command to stop all processes
        
    Returns
        lock true monitor true
        
    Playground
        catch {_daemonAction physician stop}
        catch {_daemonAction physician start}
        _daemonAction sandbox stop true
    
    Notes
        -The lock manager holds a lock connection to the databases so if you kill it all threads must be down. I killed it without stopping proceces
            and then tried to resend a transcaction and the thread and process immediately shut down. Ellen says it can also corrupt the db if you 
            pull the rug out from it. So basically shut down all processes prior to shutting down the lock manager.
        -If you try to kill the lock prior to the monitor, the command will yell at you to do the monitor first.
        -The monitor restarts itself in about 5 seconds upon stopping it due to a setting in Global Monitor. "Preferences > System"
        -In testing there frequently would be multiple monitors running for my site. I think this is either an issue with me playing with the daemons
            or more likely a timeout type of issue where GM cannot see the monitor running and thinkts its down and starts it up. Also, the gui is
            pretty dumb here. If you delete the pid file it will assume there is no process running, so to experience this, simply delete the pid and 
            refresh the gui or command line and it will say its down.
        -The processes do not need to be down to stop the monitor daemon.
        -Issuing the stop/start/restart command is synchronous, unlike a process start. In a process starting it is async.
    
    Dependencies
        _siteSet up to 1 exec
        _daemonState 2 exec
        _processList 0 exec
        _processAction 7*processcount (if stopping)
    
    This script has this many execs:
        1
    
    Change Log:
        9/8/2017 - TMH
            -Took from a rough concept to a working script
            -Seperated clean daemon code to its own sub proc
            -Added "what" parameter to do one at a time
            -Added support for restart action, has to have -d 1 for delay
            -Similar to processAction, this no longer cleans up before a start, only on stops
            -Was going to add -f but ultimately decided that wasnt safe, even on force I manually
                kill pids
        07/10/2019 - TMH
            -Quiclk fix ifg you are forcing add -f
}
#

proc _daemonAction {site action {what "l,m"} {force false}} {
    # Initialize
    global env
    set HCIROOT $env(HCIROOT)
    set swhat [split $what ","]
    
    # Ensure we are on the correct site
    _siteSet $site
    
    # If you want to stop/restart the lock manager you need to stop the processes first
    if {($action=="stop" || $action=="restart") && [lsearch $swhat "l"]>=0} {
		set processes [_processList $site]
		_processAction $site [join $processes ","] "stop"
		
		# If we are stopping lock you need to stop the monitor first before you can do 
		# the lock so add to the what list
		set what "l,m"
	}
	
    # Determine the command to run
    set cmd ""
    if {$force} {
    set cmd "-f "
    }
    set cmd "$cmd -s $what"
    set result true
    if {$action=="stop"} {
        set cmd "$cmd -k $what"
        set result false
    } elseif {$action=="restart"} {
        set cmd "$cmd -d 1 -r $what"
    }
    
    # Issue the command to start/stop/restart
    set output [exec ksh -c "hcisitectl $cmd"]
    
    # If the action was to stop, ensure we clean up
    if {$action=="stop" && $force} {
        _daemonClean $site $what $force
    }
    
    # Get the current state of both daemons
    return [_daemonStates $site [dict create includeProcessCount true]]
}
#