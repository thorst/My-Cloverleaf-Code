if 0 {
    Summary:
        The tricky part here is that Global Monitor starts The
        monitor daemon, so its risky to remove the pid file
        
        Also the lock manager is extremely critical to the stability
        of the site so killing it is very dangerous.
        
        The assumption, if you are here, is that you want to force
        the killing of these. There is still a parameter, but basically
        this script wont do anything unless you force it.
    
    Called From:
        _daemonAction
        
    Change Log:
        2017/09/26 - TMH
            -Initial Version
} 
proc _daemonClean {site what {force false}} {
    global env
    set HCIROOT $env(HCIROOT)
    
    # Ensure we are on the correct site
    _siteSet $site
    
    # Get a list of individual daemons we are acting on
    set swhat [split $what ","]
    
    # Should we clean the monitor?
    if {$force && [lsearch "m" $swhat]>=0} {
    
        # Cleanup pid file
        set pid [file join $HCIROOT $site exec hcimonitord pid]
        if {[file exists $pid]} {
            catch {exec ksh -c "kill -9 `cat $pid`"}
            file delete -force $pid
        }
        
        # Cleanup command port file
        catch {file delete -force [file join $HCIROOT $site exec hcimonitord cmd_port]}
        
        # Clean errant processes
        set pids [_pidSearch [dict create term "hcimonitord -S $site$"]]
        foreach p $pids {
            _pidKill [dict get $p pid]
        }
    }
    
    # Should we clean the lock?
    # This one doesnt autostart, but at the same point killing
    #   is extremely detremental
    if {$force && [lsearch "l" $swhat]>=0} {
    
        # Cleanup pid file
        set pid [file join $HCIROOT $site exec hcilockmgr pid]
        if {[file exists $pid]} {
            catch {exec ksh -c "kill -9 `cat $pid`"}
            file delete -force $pid
        }
        
        # Clean errant processes
        set pids [_pidSearch [dict create term "lm .*$site "]]
        foreach p $pids {
            _pidKill [dict get $p pid]
        }
    }
    
    ## Delete stray sem files
    ## This is removed because of the monitor autostarting
    # set sems [glob -nocomplain -directory [file join $HCIROOT $site exec] "sem_0x*"]
    # foreach sem $sems {
    #     catch {file delete -force $sem}
    # }
}