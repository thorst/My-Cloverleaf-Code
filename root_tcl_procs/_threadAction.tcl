if 0 {
    _threadAction site process thread action ?updateCache?

    Param:
    site - 'sandbox'
    process - 'sandbox2'
    thread - ''
    action - stop or start

    Purpose:
    This function will start and stop a thread as needed. The starting/stopping
    is performed async

    Example:
    _threadAction sandbox sandbox2 "conn_28" stop false
    _threadAction sandbox sandbox2 "conn_28,conn_27" restart

    Example of bounce:
    _threadAction $site $process $thread stop false
    _threadAction $site $process $thread start

    History:
    01/03/2017 - TMH
    -Updated to send stats directly to _intMonSingle
    -Converted to _dictGet
    10/05/2017 - TMH
    -Cleaned up documentation here in the top
    -Cleaned up and commented code, removed a bunch of legacy code
    that was used prior to global monitor
    -Added multiple thread support, send in comma seperated list
    -THEY MUST ALL BE IN THE SAME PROCESS
    -If it returns sucesful all threads sent will have that state,
    if ANY arent it will return a fail
    -Added support for restart
    -Updated wait to be 200ms instead of 100ms between query stats, seemed too short
    12/11/2018 - TMH
    -Updated tested with windows
    04/18/2022 - TMH
    -Added the ability to send in BOUNCE instead of restart
    -Changed the stop/start command to be a list of parameters instead of a long string AND wrapped in a catch

    Console:
    In researching, these commands can handle multple threads. So far it looks like they all have to be contained in the
    same process though.

    hcicmd -s sandbox -p sandbox2 -c "conn_28,conn_27 pstop"
    hcicmd -p sandbox2 -s sandbox -t d -c "statusrpt {conn_28 conn_27}"
}
#

proc _threadAction {site process thread action {updateCache true}} {
    global env tcl_platform

    # Get the platform
    set Platform $tcl_platform(platform)

    # Determine what desired output should be and
    # adjust the command if its a restart to include delay
    set newStat false
    set cmd "p$action"
    if {$action=="start"} {
        set newStat true
    } elseif {$action=="restart" || $action=="bounce" } {
        set newStat true
        set cmd "$cmd 0"
    }

    # Ensure the process is running if they want to start
    # Interfaces wont start otherwise
    set procState [_processState $site $process]
    if {$procState!="running" && $newStat==false} {
        return $newStat;
    } elseif {$procState!="running"} {
        _processAction $site $process start
    }

    # Initialize the output variable
    set output ""

    # Command is different based on platform
    if {$Platform=="windows"} {
        #         set ::env(QT) \";                        #Set environment variable for "
        #         set command "hcicmd -s $site -t d -p $process -c %QT%$thread p$action%QT%"
        #         set cmd $::env(ComSpec);                #Get path to cmd
        #         set output [exec $cmd /C $command]
        catch {exec cmd /C hcicmd -s $site -p $process -c "$thread $cmd"]}
    } else {
        catch {exec ksh -c [list hcicmd -s $site -p $process -c '$thread $cmd']}
    }

    # Because actions are performed asynchonously we need to loop over
    # to check for 15 seconds on the status
    set start [clock seconds]
    set Status "Down"
    set result ""
    set thread [split $thread ","]
    while {[expr [clock seconds]-$start]<=15} {
        # Reset whether we think this was succesful, starting off assuming it was
        set success 1

        # Get the status
        set result ""
        if {$Platform=="windows"} {
            set result [exec cmd /C hcicmd -p $process -s $site -t d -c "statusrpt \{$thread\}"]
        } else {
            set result [exec ksh -c "hcicmd -p $process -s $site -t d -c \"statusrpt \{$thread\}\""]
        }

        foreach t [lrange $result 2 end] {

            # Get objects keyed list
            set kl [lindex $t 1]

            #Get Alive - Is there pstatus (up, down, connecting)
            set ALIVE [_keylget $kl "ALIVE"]
            if {$ALIVE==1} {set ALIVE true;} else {set ALIVE false;}

            # If one of the threads in list doesnt match the desired output
            # then exit the list of thread statuses
            if {$newStat!=$ALIVE} {
                set success 0
                break
            }
        }

        # If at least one thread doesnt match desired output
        # then wait 100 ms and check again
        # else exit status loop
        if {$success} {
            break
        } else {
            after 200
        }
    }

    # After this point we have tried up to 15 secconds
    if {$success} {

        # If they want to update cache, this will refresh rogermon so that the monitor is accurate
        if {$updateCache} {
            set threads ""
            foreach t [lrange $result 2 end] {

                # Build with info we dont need to retrieve
                set dthread [dict create Site $site Name [lindex $t 0] Alive $newStat Process $process]

                # Get objects keyed list
                set kl [lindex $t 1]

                set Status [string totitle [_keylget $kl PSTATUS]]
                dict append dthread Status $Status

                set LastWrite [clock format [_keylget $kl PLASTWRITE "Never"] -format "%m/%d/%Y %H:%M:%S"]
                dict append dthread LastWrite $LastWrite

                set LastRead [clock format [_keylget $kl PLASTREAD "Never"] -format "%m/%d/%Y %H:%M:%S"]
                dict append dthread LastRead $LastRead

                set Pending [_keylget $kl OBDATAQD]
                dict append dthread Pending $Pending

                dict append dthread DataError [_keylget $kl ERRORCNT]
                dict append dthread ReplyError 0

                lappend threads $dthread
            }

            #Trigger update for intmon
            _intMonSingle $threads
        }

        return $newStat
    } else {
        # 15 seconds passed and it still didnt start
        error "Thread(s) not responding" "Tried for 15 seconds, one or more thread still not responding."
    }
}
#