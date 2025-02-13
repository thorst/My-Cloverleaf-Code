if 0 {
    Given a list of threads and the site they belong to return a dict of dict of
    thier statuses. This is just a high level and doesnt include all the routes.
	
	Updates:
	12/27/2016 Todd H.
	    -Created version based off of older _threadStat.tcl global proc.
	    -This version doesnt assume a dictionary of threads and instead
	        takes a list of threads. It is also cleaner in that it doesnt assume
	        its being called from cron and therefore doesnt echo anything.
	    -This version creates a dictionary of dictionaries instead a list of 
	        dictionaries to make grabbing your thread a bit easier
}


proc _threadListStat {site threads} {

    # Initialize response
    set response [dict create \
        threads "" \
        error "" \
        successful true \
    ]
    
    # Verify site / threads parameters
    if {$site=="" || [llength $threads]==0} {
        dict set response error "Thread list or site parameter empty."
        dict set response successful false
        return $response
    }
   
    # Get the state of the daemons, if off try to start them
    set dStates [_daemonState $site]
    if {![dict get $dStates lock] || ![dict get $dStates monitor]} {
        catch {_daemonAction $Site start}
    }
  
    # Try gettings stats one time
    set statuses ""
    set output ""
    set err ""
    set herr [catch {
            set statuses [exec ksh -c "hcicmd -s $site -t d -c \"statusrpt \{$threads\}\""]
            set statuses [lrange $statuses 2 end]
    } output err]
    
    # There was an error getting stats, usually due to the deamon
    # Bounce deamon and try again
    if {$herr==1} {
        catch {_daemonAction $site stop}
        catch {_daemonAction $site start}
        set herr [catch {
            set statuses [exec ksh -c "hcicmd -s $site -t d -c \"statusrpt \{$threads\}\""]
            set statuses [lrange $statuses 2 end]
        } output err]
        
        # We erroed again so respond as such
        if {$herr==1} {
            dict set response error "Unable to get statuses. May be due to deamon issues."
            dict set response successful false
            return $response
        }
    }
  
    # Loop over status and build dictionary
    set statusthreads [keylkeys statuses]
    set responseThreads ""
    foreach thread $statusthreads {
        set status [keylget statuses $thread]
     
        dict append responseThreads $thread [dict create \
            status [_keylget $status "PSTATUS"] \
            queue [_keylget $status "OBDATAQD"] \
            write [_keylget $status "PLASTWRITE"] \
            read [_keylget $status "PLASTREAD"] \
            error [_keylget $status "ERRORCNT"] \
        ]
    }

    # Return the dictionary
    dict set response threads $responseThreads
    return $response
}

##Handle command line
#if {$argc>0} {
#
#    set ScriptName $argv0
#    set ScriptDir [join [lrange [split [string map {\\ /} $ScriptName] "/"] 0 end-1] "/"]
#echo $ScriptDir
#    # cd to script location
#    cd "$ScriptDir/../"
#
#    return _threadStat
#}

