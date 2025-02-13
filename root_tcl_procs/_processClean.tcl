if 0 {
    _processClean - cleans up a process, if there is a force it will
    clean up and running proccess
}
proc _processClean {site process {force false}} {
    global env
    
    # Set site to this site if we havent already
    _siteSet $site
    
    # If there is a pid file read it and kill process, then delete
    set pid [file join $env(HCIROOT) $site exec processes $process pid]
    if {[file exists $pid]} {
        catch {exec ksh -c "kill -9 `cat $pid`"}
        file delete -force $pid
    }
    
    # If there is a wpid file read it and kill process, then delete
    set wpid [file join $env(HCIROOT) $site exec processes $process wpid]
    if {[file exists $wpid]} {
        catch {exec ksh -c "kill -9 `cat $wpid`"}
        file delete -force $wpid
    }
    
    # If we want to force it being down we can look for other instances of that process
    if {$force} {
        set pids [_pidSearch [dict create term "-S $site -p $process"]]
        foreach p $pids {
            _pidKill [dict get $p pid]
        }
    }
    
    #Cleanup site processes
    catch {file delete -force [file join $HCIROOT $site exec processes $process cmd_port]}
    catch {file delete -force [file join $HCIROOT $site exec processes $process startup_log]}
    catch {file delete -force [file join $HCIROOT $site exec processes $process exit_log]}
    
    #Cleans up after a crashed engine that has not disconnected from the Lock Manager properly.
    catch {exec ksh -c "hcilmclear -p $process"}
}