if 0 {
    VERSION::
    2.0
    ABOUT::
    This provides general rest or soap capabilities to tcl.
    CHANGE LOG::
    1.0: 3/22/2012
    ext_json_parse-
    ext_curl_exec-
    Logging
    Timeout
    Reply/Error/Error Code
    Error out message
    Shut thread down
    Log to central log
    Persistent Connection
    1.1: 8/27/2012
    Removed destroy/connect - Each connection creates and destroys a session, this isnt logged anymore, this allows
    you to remove the unset function to allow multiple calls per script (or 1 call, then next message makes another call)
    this was causing a real interface to fail, and unsetting will cause the init function to repeatedly run
    Added json date parser - pass in the date and the intended format, setup for future release to consider timezone
    Prelim cleanup/code review
    1.2: 11/19/2012
    ext_json_parse_date was not specifying gtm. Since all epoch is gmt added  -gmt true to clock format
    2.0: 06/17/2013
    -Basically a rewrite, though most pieces existed somewhere in 1.x
    -Refactor to remove connection from global. This needs to be created each time, or it gums up.
    -Pulled curl into its own file seperate from json functions
    -Pulled out curl_handleError as user should call if the service returned an error
    -Safe globaling
    -Added procpath used for safe globaling
    -Added callingproc to determine who called handleerror
    -Global now only contains the read only keys
    -Local variable no longer removed
    -Local variable contains only editable feilds + response items
    -Added error_code to local varaible instead of just returning from exec
    -Split debug proc setting out as you cannot use verbose and debug proc simulatenously
    2.1: 06/17/2013-02/17/2015
    -There have been multiple small patches to fix or add functionality
    -Disable ssl verification (sslverifypeer && sslverifyhost)
    -http auth (ntlm/basic)
    set req(userpwd) "un:pw"
    set req(httpauth) "ntlm"
    -$lsettings(post) & $lsettings(put)
    3.0: 07/13/2016
    -re-envisioned version
    -dictionaries instead of arrays
    -debug custom proc so it works with clovertools testing tool
    -onError annonomous proc

    TODO::
    -There is no retry. So if a message fails its done.
}
#

if 0 {
    #################################################################
    # post the xml using curl::transfer
    # the following args are passed:
    # X-url: the url to post to
    # -sslverifypeer: to verify or not to verify the peer's certificate
    # X-post: do a http post
    # X-postfields: data to post
    # -httpheaders: list of headers to use
    # -headervar: variable containing the reply headers from the post
    # X-bodyvar: variable containing the reply from the post
    # X-errorbuffer: variable containg error text
    # X-verbose: useful in debugging   ****REMOVE FROM PRODUCTION'S VERSION.
    # X-debugproc: used for debugging  ****REMOVE FROM PRODUCTION'S VERSION.
    #################################################################
}
#

if 0 {
    _curl
    Performs a basic web transaction GET/POST/PUT. Returns status of trasnaction. 0 == successful.

    Some Help:
    http://pwet.fr/man/linux/fonctions_bibliotheques/tclcurl
    http://personal.telefonica.terra.es/web/getleft/tclcurl/examples.html

    Tcl:
    package require TclCurl
    set connection [curl::init]
    $connection configure -test

    Output:
    #-url, -file, -infile, -useragent, -referer, -verbose, -header, -nobody, -proxy, -proxyport, -httpproxytunnel, -failonerror, -timeout, -lowspeedlimit,
    #-lowspeedtime, -resumefrom, -infilesize, -upload, -ftplistonly, -ftpappend, -netrc, -followlocation, -transfertext, -put, -mute, -userpwd, -proxyuserpwd,
    #-range, -errorbuffer, -httpget, -post, -postfields, -postfieldssize, -ftpport, -cookie, -cookiefile, -httpheader, -httppost, -sslcert, -sslcertpasswd,
    #-sslversion, -crlf, -quote, -postquote, -writeheader, -timecondition, -timevalue, -customrequest, -stderr, -interface, -krb4level, -sslverifypeer, -cainfo,
    #-filetime, -maxredirs, -maxconnects, -closepolicy, -randomfile, -egdsocket, -connecttimeout, -noprogress, -headervar, -bodyvar, -progressproc,
    #-canceltransvarname, -writeproc, -readproc, -sslverifyhost, -cookiejar, -sslcipherlist, -httpversion, -ftpuseepsv, -sslcerttype, -sslkey, -sslkeytype,
    #-sslkeypasswd, -sslengine, -sslenginedefault, -prequote, -debugproc, -dnscachetimeout, -dnsuseglobalcache, -cookiesession, -capath, -buffersize, -nosignal,
    #-encoding, -proxytype, -http200aliases, -unrestrictedauth, -ftpuseeprt, -command, -httpauth, -ftpcreatemissingdirs, -proxyauth, -ftpresponsetimeout,
    #-ipresolve, -maxfilesize, -netrcfile, -ftpssl, -share, -port, -tcpnodelay, -autoreferer, -sourcehost, -sourceuserpwd, -sourcepath, -sourceport, -pasvhost,
    #-sourceprequote, -sourcepostquote, -ftpsslauth, -sourceurl, -sourcequote, -ftpaccount, -ignorecontentlength, -cookielist, -ftpskippasvip, -ftpfilemethod,
    #-localport, -localportrange, -maxsendspeed, -maxrecvspeed, -ftpalternativetouser, -sslsessionidcache, -sshauthtypes, -sshpublickeyfile, -sshprivatekeyfile,
    #-timeoutms, -connecttimeoutms, -contentdecoding, or -transferdecoding' header_reply

    Implemented:
    -url
    -sslverifypeer
    -sslverifyhost
    -errorbuffer
    -bodyvar
    -timeout
    -verbose
    -debugproc
    -put
    -post
    -postfields
    -httpheader
    -userpwd
    -httpauth
}
#

if 0 {
    _curl_i_dP is a debug proc not intended for external use. It tries to mimic the
    output of the normal debug mode, while keeping it more syncrhonous. This was
    the issue with the last version and clovertools testing tool.
}
#
proc _curl_i_dP {infoType data} {
    if {$infoType==6 || $infoType==5} {return;}
    if {$infoType==0} {puts -nonewline "* ";}
    if {$infoType==2} {puts -nonewline "> ";}
    if {$infoType==1} {puts -nonewline "< ";}
    echo [string trim $data]
}
#

if 0 {
    _curl The meat and potatoes of the file, this proc will make the call and call
    logging and error procs as needed
}
#
proc _curl { {request not_defined} } {

    # Obviously you need to send in some settings
    if {$request=="not_defined"} {
        set mess "_curl Error:: Settings are not defined."
        set year [clock format [clock seconds] -format "%Y"]
        return;
    }

    # At minimum the url is required
    set url [_dictGet $request url]
    if {$url==""} {
        echo "_curl Error:: url is not defined in settings."
        return false
    }

    # Get the curl calls alias, if user wants to enable having multiple calls
    set alias [_dictGet -default "_curlSettings" $request alias]
    set procpath [_curl_i_procpath]
    set globalVar $procpath\_$alias

    # Add global var so the curl_i_init knows where to look
    dict set request globalVar $globalVar

    # Gettings global settings
    if {[info globals $globalVar]==""} {                                        ;# If the global doesnt exist we need to create it
    upvar #0 $globalVar gsettings							                ;# Create global using same settings name
    set gsettings [_curl_i_init $request]                                                ;# Populate global
} else {
    upvar #0 $globalVar gsettings                                           ;# If global exists, grab reference
}

# Begin setting up connection with url
package require TclCurl
set connection [curl::init]
$connection configure -url $url

# Disable ssl verification
# Every https call will fail if this isnt here. curl doesnt ship with ca auth list
$connection configure -sslverifypeer 0
$connection configure -sslverifyhost 0

# Reply and Error settings
set error "";
set reply "";
$connection configure -errorbuffer error
$connection configure -bodyvar reply

# Timeout in seconds
set timeout [_dictGet -default 15 $request timeout]
$connection configure -timeout $timeout

# Allow username and password to be sent
set userpwd [_dictGet $request password]
if {$userpwd!=""} {
    $connection configure -userpwd $userpwd
}
set httpauth [_dictGet $request user]
if {$httpauth!=""} {
    $connection configure -httpauth $httpauth
}

# Debug proc
if {[_dictGet -default false $request debug]} {
    #echo 0 text, 1 incoming header, 2 outgoing header, 3 incoming data, 4 outgoing data, 5 incoming SSL data, 6 outgoing SSL data
    $connection configure -verbose 1
    $connection configure -debugproc _curl_i_dP
}

# If its a post
set post [_dictGet $request post]
if {$post!=""} {
    $connection configure -post 1 -postfields $post
}

# If its a put
# http://stackoverflow.com/questions/3958226/using-put-method-with-php-curl-library
set put [_dictGet $request put]
if {$put!=""} {
    $connection configure -put 1 -postfields $put
}

#If there are any headers
set httpheader [_dictGet $request headers]
if {$httpheader!=""} {
    $connection configure -httpheader $httpheader
}

#Run curl
set errorCode ""
catch {$connection perform} errorCode

#cleanup connection per tclcurl examples
$connection cleanup

#If it was successful
if {$errorCode=="0"} {
    # Clear error count
    dict set gsettings errorCount 0

    #If there was an error
} else {
    _curl_handleError $globalVar $request $error
}

# Return results
return [dict create \
    error $error \
    reply $reply \
    errorCode $errorCode \
    globalVar $globalVar \
    request $request
];
}
#

if 0 {
    handleError will allow the user to incr the error count and easily error msg/shutdown thread
}
proc _curl_handleError { globalVar settings error} {
    set mh ""
    catch {upvar #1 mh mh}
    upvar #0 $globalVar gsettings                                                                                            ;# If global exists, grab reference

    # Get thread and proccess
    set now [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
    set threadProcess [_dictGet $gsettings threadProcess]
    set threadName [_dictGet $gsettings threadName]
    set procPath [_dictGet $gsettings procPath]
    set logFile [_dictGet $gsettings logFile]



    # Define Error
    set mess "Time:\t\t\t$now\n"
    append mess "Thread:\t\t\t$threadProcess.$threadName.$procPath\n"
    append mess "Url:\t\t\t[_dictGet $settings url]\n"
    append mess "Static Error:\t\tCurl Failed in curl_exec\n"
    append mess "Returned Error:\t\t$error\n"
    if {[dict exists $settings post]} {append mess "Post:\t\t\t[_dictGet $settings post]\n"}
    if {[dict exists $settings put]} {append mess "Put:\t\t\t[_dictGet $settings put]\n"}
    append mess "Log:\t\t\t$logFile\n"

    # Echo the error to the process log
    echo "===CURL Error==="
    echo $mess

    # Write to the log
    set year [clock format [clock seconds] -format "%Y"]
    _curl_i_log $logFile.$year.txt $mess

    # Increment the error count, and get the output (returns the key/val pair)
    set count [lindex [dict incr gsettings errorCount] 1]


    # Refresh global settings with locals
    set throw [_dictGet -default true $settings throwError]
    set shutdown [_dictGet -default true $settings allowShutdown]
    set threshold [_dictGet -default 3 $settings errorThreshold]



    # Shut down thread if exceeded repeat error threshold
    if {$count>=$threshold && $shutdown} {
        # If its inside the engine
        if {$threadProcess!="TEST" && $threadName!="TEST"} {
            catch {exec hcicmd -p $threadProcess -c "$threadName pstop"} catch_return	                    ;# Then shut down the thread
        }
    }

    set onError [_dictGet $settings onError]
    if {$onError!=""} {
        apply $onError [dict create \
            mess $mess \
            gsettings $gsettings \
            settings $settings \
            error $error
        ]
    }

    # Error this message if needed
    if {$throw && $mh!=""} {
        msgmetaset $mh USERDATA "CURL Error:: Check process log OR $logFile for details."                       ;# Set meta data of message as well
        echo $CURL_ERROR_See_USERDATA_for_details								                                ;# Throw a tcl error
    }
}
#

if 0 {
    enable xml encoding and decoding
}
proc _curl_escape { param } {
    package require TclCurl
    return [curl::escape $param]
}
proc _curl_unescape { param } {
    package require TclCurl
    return [curl::unescape $param]
}

# ;;;;;;;;;;;;;;;;;;;;;;;
# ;;;;#Private Functions
# ;;;;;;;;;;;;;;;;;;;;;;;

if 0 {
    About:
    curl_internals_log gets called from procs in this file. Simply write a string to a file.

    Example:
    #Write to the log
    set year [clock format [clock seconds] -format "%Y"]
    catch {curl_internals_log $settings(log_file).$year.txt $mess} catch_return

    Param List:
    ErrFile- The file to log the message to
    Message- The message to log

    Returns:
    String- Whether it succesfully logged the comment
}
proc _curl_i_log {ErrFile Message} {
    catch {
        set entireMess "Check  for more details on CURL\n"
        append entireMess "$Message"
        set log [open "$ErrFile" {WRONLY CREAT APPEND}]	;# Open error log
        puts $log "$entireMess"				            ;# Put the error message in the error log
        close $log						                ;# Close error log
        } catch_return

        return $catch_return
    }
    #

    if 0 {
        This is used to get the root proc to prefix global
    }
    proc _curl_i_procpath {} {
        #Return the path of procs excluding any curl_*

        # the first and last proc names are the current proc and should be the same
        #echo [info level 0] ;# current proc
        #echo [info level 1] ;# root proc
        #echo [info level 2] ;# #1 called
        #echo [info level 3] ;# #2 called

        #get calling proc
        #echo [lindex [info level [expr [info level]-1]] 0]

        set result [list]
        for { set i 1 } { $i <= [info level]-1 } { incr i 1 } {
            set procname [lindex [info level $i] 0]
            if {[string compare -length 6 $procname "_curl_"]==1} {
                lappend result $procname
            }
        }

        return [join $result "_"]
    }
    #

    # if 0 {
    #     This is used to get the root proc to prefix global
    # }
    # proc curl_internals_callingproc {} {
    #     return [lindex [info level [expr [info level]-2]] 0]
    # }
    # #



    if 0 {
        About:
        _curl_i_init very close to odbc equiv, sets up some thread details but nothing related to the connection or calls
    }
    proc _curl_i_init { settings } {
        # Get global and mh reference
        upvar #1 mh mh

        # Get env and thread name
        global env HciRoot HciSiteDir HciConnName

        # Create the procPath
        set result [list]
        for { set i 1 } { $i <= [info level]-2 } { incr i 1 } {
            lappend result [lindex [info level $i] 0]
        }
        set procPath [join $result ">>"]

        # Ensure HciConnName defined
        if {![info exists HciConnName]} {
            set HciConnName "TEST"
        }

        # Get the thread and process name
        set threadProcess "TEST"
        set threadName $HciConnName
        if {[string match "*_xlate" $threadName)]} {                ;#If there is xlate in the name, its probably on the route of a thread "%processname%_xlate"
        catch {
            set sourceconn [msgmetaget $mh SOURCECONN]          ;#Get the source thread
            if {[string trim $sourceconn]!=""} {                ;#Make sure its not blank, Id rather have a funcky filename then none at all
            set threadName $sourceconn                      ;#Reset the thread name
        }
        } cat_ret
    }

    # Get the real process name
    netcfgLoad $env(HCISITEDIR)/NetConfig		                ;# Load net config
    set connData [netcfgGetConnData $threadName]	            ;# Get data for this thread
    keylget connData PROCESSNAME procName		                ;# Get the Process Name
    if {$connData!="" && [info exists procName]} {
        set threadProcess $procName
    }

    #Get log filename somethign like: /qdx5.7/integrator/logs/curl/site/threadname.year.txt
    set siteName "TEST"
    if {$threadProcess!="TEST"} {
        set siteName [lindex [file split $HciSiteDir] end]
    }

    set logFile [_dictGet $settings logFile]
    if {$logFile==""} {
        set logFile [file join $HciRoot logs curl $siteName $threadName]
    }

    #Ensure log directory exists
    set logDir [file dirname $logFile]
    if {![file isdirectory $logDir]} {
        mkdir $logDir
    }

    # Build settings
    set gsettings [dict create \
        logFile $logFile \
        siteName $siteName \
        threadProcess $threadProcess \
        threadName $threadName \
        procPath $procPath \
        errorCount 0 \
        procPath $procPath \
        globalVar [_dictGet $settings globalVar] \
        errorCount 0
    ]

    # Return those settings
    return $gsettings
}
#


# ;;;;;;;;;;;;;;;;;;;;;;;
# ;;;;#Test Functions
# ;;;;;;;;;;;;;;;;;;;;;;;

# proc curl_test {args} {
#     #Clear message
# 	keylget args MSGID "mh"
# 	msgset $mh ""

#     package require TclCurl
#     set connection [curl::init]
# 	$connection configure -test


#     lappend dispList "KILL $mh"
#     return $dispList
# }
# #


