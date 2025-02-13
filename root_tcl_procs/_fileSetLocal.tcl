
######################################################################
# Name:      tps_FileSetLocal_Parse
# Purpose:   This script gets called at the interval set at:
#            thread tab>Protocol:fileset-local>properties>Scheduling>Scan Interval
#            Default is 30 seconds. It then builds the list of files to read in what
#            order.            
# 
# UPoC type: tps
# Args:      tps keyedlist containing the following keys:
#            MODE    run mode ("start", "run", "time" or "shutdown")
#            MSGID   message handle
#            CONTEXT tps caller context
#            ARGS    user-supplied arguments:
#                    LOG    | Default:  0 | 0 = false, 1 = true, Will save to /qdxitest/qdx5.7/integrator/logs/FileSetLocal
#                    ALPHA  | Default:  0 | 0 = false, 1 = true, Will sort filesname alphabetically
#		     ECHO   | Default:  0 | 0 = false, 1 = true, Will show filenames in process log
#	     Example
#		{Log 1} {Echo 1}
#
# Returns:   tps disposition list:
#            <describe dispositions used here>
#
# Notes:
#  Once a file list is submitted cloverleaf will not rescan until it
#  has completed processing this list, UNLESS the thread gets bounced.
#
#  Use "istat filename.txt" to get meta details about your files.
#
#  Opening a file in tcl "set fh [file open filename]" doesnt affect any timestamps
#
#  If the file is a local file that is copied by tcl [file copy fn fn]:
#	-The updated time will be when the copy is complete
#	-The modified time is the same as the source files modified time
#	-The accessed time will be the accessed time from the source file
#	 Because of the copy, it will then set a new accessed time of the source to be the current time
#
#  If the file is a local file that is copied by unix [cp fn fn]:
#	-The updated time will be when the copy completed
#	-The updated time will be when the copy completed
#	-The accessed time will be when the copy started
#	 Because of the copy, it will then set a new accessed time of the source to be the current time
#
#  If the file is ftp'd
#	-The updated time will be when the copy completed
#	-The updated time will be when the copy completed
#	-The accessed time will be when the copy started
#
#  If the file is a local file that is moved/renamed by unix [mv fn fn]:
#	-The updated time will not be changed
#	-The updated time will not be changed
#	-The accessed time will not be changed
#
#  If the file is a local file that is moved/renamed by tcl [file rename fn fn]:
#	-The updated time will not be changed
#	-The updated time will not be changed
#	-The accessed time will not be changed
#
# History:
#  12.14.2010 Todd H. 	-Updated to allow for filesetlocal with static path
#  06.12.2014 Ellen   	-Loop over file list and sort by time to make it chrono
#  06.17.2014 Todd H. 	-Rewrite from scratch
#                   	-Added:   Unix ls command instead of list they provide for better sort/filename with spaces
#                       -Added:   Logging
#                       -Changed: locked check now uses [open filename] as a test instead of arbitrary time
#                       -Changed: now i through out from the locked file till end of list, not just throwing out locked file, maintain chrono order
#						-Changed: Renaming spaced filenames to be on the fly 
#  03/28/2016 Todd H.   -Copied into _ library

proc _FileSetLocal_Parse { args } {
    global HciConnName env HciProcessesDir ProtInbDir ProtInbLog ProtInbEcho
    
    keylget args MODE mode                         ;# Fetch mode
    set ctx ""   ; keylget args CONTEXT ctx        ;# Fetch tps caller context
    set uargs {} ; keylget args ARGS uargs         ;# Fetch user-supplied args

    set debug 0  ;                                 ;# Fetch user argument DEBUG and
    catch {keylget uargs DEBUG debug}              ;# assume uargs is a keyed list

    set module "tps_WaitFileSetLocal3/$HciConnName/$ctx"

    set dispList {}                                ;# Nothing to return

    # get user arguments
    keylget args MSGID mh
    keylget args ARGS uargs
    
    set uargs [string toupper $uargs]
    
    set Logging  0						;#Default logging to false
    keylget uargs LOG Logging
    
    set AlphaSort  0						;#Default sorting chrono
    keylget uargs ALPHA AlphaSort

    set ProtInbEcho 0						;#Default sorting chrono
    keylget uargs ECHO ProtInbEcho
    
    switch -exact -- $mode {
        start {
            # load conn data
            netcfgLoad $env(HCISITEDIR)/NetConfig		;# Load net config
            set connData [netcfgGetConnData $HciConnName]	;# Get data for this thread
            
            # pull ib path data
            keylget connData PROCESSNAME procName		;# Get the Process Name
            keylget connData PROTOCOL protDetails		;# Get the Protocal Details
            keylget protDetails IBDIR inDIR			;# Get subkey Inbound Dir
            
            # if the path starts with root its static, else build a static path from dynamic            
            if {[string index $inDIR 0]=="/"} {
                set ProtInbDir $inDIR
            } else {
                set ProtInbDir "$HciProcessesDir/$procName/$inDIR"
            }
            
            # determine logging if set
            set ProtInbLog ""
            if {$Logging} {
                # determine log file name
                keylget connData PROCESSNAME PROCESSNAME
                set ProtInbLogDir "$env(HCIROOT)/logs/FileSetLocal/$env(HCISITE)/$PROCESSNAME/"
                set ProtInbLog "$ProtInbLogDir$HciConnName.[clock format [clock seconds] -format %U].txt"
                
                # ensure dir exists
                file mkdir $ProtInbLogDir
                
                # write initial data
                set fl [open $ProtInbLog a+]
		puts $fl ""
                puts $fl "[clock format [clock seconds]] - Reading $ProtInbDir"
                close $fl
            }
        }

        run {
            
            #####################################################
            # Check for correct context
            #
            if {![cequal $ctx "fileset_ibdirparse"]} {
                echo "ERROR $module used in wrong context"
                echo "Context should be fileset_ibdirparse"
                echo "Proc called in: $ctx"
            }
            
            #####################################################
            # Original list
            #
            #set fileList [msgget $mh]
            #echo Original List $fileList
            
            #####################################################
            # New list
            # ls List files command
            # -t Sorts by time of last modification (latest first) instead of by name. For a symbolic link, the time used as the sort key is that of the symbolic link itself.
            # -c Uses the time of last modification of the i-node for either sorting (when used with the -t flag) or for displaying (when used with the -l flag). This flag has no effect if it is not used with either the -t or -l flag, or
            #       both.
            # -r Reverses the order of the sort, giving reverse alphabetic or the oldest first, as appropriate.
            # -u Uses the time of the last access, instead of the time of the last modification, for either sorting (when used with the -t flag) or for displaying (when used with the -l flag). This flag has no effect if it is not used with
            #       either the -t or -l flag, or both.
            #
            set fileList ""
            if {$AlphaSort} {
                set fileList [split [exec ls "$ProtInbDir"] \n]
            } else {
                set fileList [split [exec ls -tur "$ProtInbDir"] \n]    
            }
	    if {$ProtInbEcho} {
		echo fileList initial:$fileList
	    }
            
            #####################################################
            # Remove too new files / not done ftping / locked files
            # Our initial sort is by accessed time. According to my tests this is when the ftp started.
            # **If it was a copy of an existing local file the accessed time will be copied from the source.**
            #
            # Since we want to always maintain this order, I loop over the files started from the begining.
            # If I encounter one that is locked I cut that index to end.
	    #
	    # This means if a large file is uploaded and still in progress and a smaller file is uploaded and
	    # done, the large file will be locked and block the small file from being processed until the large
	    # file is no longer locked. 
            #
            for {set x 0} {$x<=[expr [llength $fileList] - 1]} {incr x} {
                set fileName "$ProtInbDir/[lindex $fileList $x]"
		set locked 1
		
		# try opening for read, this doesnt update any timestamps
		catch {
		    set fileLock [open $fileName]
		    close $fileLock
		    set locked 0
		}
		
		# it was locked so remove from here on out
		if {$locked} {
		    set fileList [lrange $fileList 0 [expr $x - 1]]
		    break;
		}
	    }
	    if {$ProtInbEcho} {
		echo fileList lock:$fileList
	    }
            
            #####################################################
            # Rename spaces
            #
	    foreach x [lsearch -all $fileList "* *"] {
		set fileName "$ProtInbDir/[lindex $fileList $x]"
		set newFileName [string map {" " "_"} [lindex $fileList $x]]
		file rename $fileName "$ProtInbDir/$newFileName"
		set fileList [lreplace $fileList $x $x $newFileName]
	    }
	    if {$ProtInbEcho} {
		echo fileList rename:$fileList
	    }
            
            #####################################################
            # Write data to log
            #
            if {$ProtInbLog !="" && [llength $fileList]>0} {
                set fl [open $ProtInbLog a+]
                puts $fl "[clock format [clock seconds]] - Found [join $fileList ", "]"
                close $fl                
            }
           
            
            #####################################################
            # Breakout without actually reading any files
            #
            #msgset $mh ""
	    #return "{CONTINUE $mh}"
            
            msgset $mh $fileList
            lappend dispList "CONTINUE $mh"
        }
    }

    return $dispList
}

######################################################################
# Name:      tps_FileSetLocal_Deletion
# Purpose:   This gets passed the file it will be deleting, but it is
#            not in charge of deleting the file. I only use this to log
#            the order in which the files were read. You dont need to
#	     add this is you arent echoing or logging.
#            
# UPoC type: tps
# Args:      tps keyedlist containing the following keys:
#            MODE    run mode ("start", "run", "time" or "shutdown")
#            MSGID   message handle
#            CONTEXT tps caller context
#            ARGS    user-supplied arguments:
#                    <describe user-supplied args here>
#
# Returns:   tps disposition list:
#            <describe dispositions used here>
#
# Notes:     <put your notes here>
#
# History:  <date> <name>
#  06/17/2014 - Todd Horst
#           Initial version just logs each file to the common log for that
#           thread, and echos to process log
#  03/28/2016 Todd H.   
#           -Copied into _ library

proc _FileSetLocal_Deletion { args } {
    global HciConnName ProtInbLog ProtInbEcho                            ;# Name of thread
    
    keylget args MODE mode                         ;# Fetch mode
    set ctx ""   ; keylget args CONTEXT ctx        ;# Fetch tps caller context
    set uargs {} ; keylget args ARGS uargs         ;# Fetch user-supplied args

    set debug 0  ;                                 ;# Fetch user argument DEBUG and
    catch {keylget uargs DEBUG debug}              ;# assume uargs is a keyed list

    set module "tps_WaitFileSetLocal3_DeleteFile/$HciConnName/$ctx"

    set dispList {}                                ;# Nothing to return

    switch -exact -- $mode {
        run {
            # get data
            keylget args MSGID mh
            set readFile [msgget $mh]
            
	    #####################################################
            # Echo data
            #
	    if {$ProtInbEcho} {
		echo readFile:$readFile
	    }
	    
            #####################################################
            # Write data
            #
            if {$ProtInbLog != ""} {
                set fl [open $ProtInbLog a+]
                puts $fl "[clock format [clock seconds]] - Read $readFile atime:[file atime $readFile] mtime:[file mtime $readFile]"
                close $fl                
            }
         
            lappend dispList "CONTINUE $mh"
        }
    }

    return $dispList
}

