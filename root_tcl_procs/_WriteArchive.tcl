if 0 {
    Script:
    _WriteArchive

    Purpose:
    Allows you to write out to the archive directory easily. This is useful forp writing
    smat for post procs if you are doing MANY routes between 2 threads.

    History:
    This is a re-write of other_CSC_SMAT that is meant to be more general purpose and
    easier to use.

    Usage:
    NO ARG                      /qdxitest/archive_QDX/sbtoddhorst/TESTING_TOOL/20160119.msg
    {fn %thread%/}              /qdxitest/archive_QDX/sbtoddhorst/TESTING_TOOL/TEST/20160119.msg
    {fn msfp}                   /qdxitest/archive_QDX/sbtoddhorst/TESTING_TOOL/msfp20160119.msg
    {fn %thread%/msfp}          /qdxitest/archive_QDX/sbtoddhorst/TESTING_TOOL/TEST/msfp20160119.msg
    {fn %thread%_msfp_}         /qdxitest/archive_QDX/sbtoddhorst/TESTING_TOOL/TEST_msfp_20160119.msg
    {fn msfp_%thread%/msfp_}    /qdxitest/archive_QDX/sbtoddhorst/TESTING_TOOL/msfp_TEST/msfp_20160119.msg

    Change Log:
    2016-01-18 TMH
    -Initial Version
    2016-09-20 TMH
    -Handle *..org*/cl/cis6.1/integrator*_ipei01 for threadname
}
#

proc _WriteArchive { args } {
    global HciConnName                             ;# Name of thread

    keylget args MODE mode                         ;# Fetch mode
    set ctx ""   ; keylget args CONTEXT ctx        ;# Fetch tps caller context
    set uargs {} ; keylget args ARGS uargs         ;# Fetch user-supplied args

    set debug 0  ;                                 ;# Fetch user argument DEBUG and
    catch {keylget uargs DEBUG debug}              ;# assume uargs is a keyed list

    set module "_WriteArchive/$HciConnName/$ctx" ;# Use this before every echo/puts,
    ;# it describes where the text came from

    set dispList {}                                ;# Nothing to return

    switch -exact -- $mode {
        run {
            # 'run' mode always has a MSGID; fetch and process it

            keylget args MSGID mh
            set data [msgget $mh]

            # Get the thread
            set thread_name $HciConnName
            if {[string match "*_xlate" $thread_name]} {  			;#If there is xlate in the name, its probably on the route of a thread
            catch {
                set sourceconn [msgmetaget $mh SOURCECONN]      ;#Get the source thread
                if {[string trim $sourceconn]!=""} {            ;#Make sure its not blank, Id rather have a funcky filename then none at all
                set thread_name $sourceconn       			;#Reset the thread name
            }
            } cat_ret
        }
        #*..*/cl/cis6.1/integrator*_ipei01
        set thread_name [lindex [split $thread_name "*"] 0]


        # Get process name
        global env
        set thread_process "TESTING_TOOL"
        netcfgLoad $env(HCISITEDIR)/NetConfig		            ;# Load net config
        set connData [netcfgGetConnData $thread_name]			;# Get data for this thread
        keylget connData PROCESSNAME procName		            ;# Get the Process Name
        if {$connData!="" && [info exists procName]} {
            set thread_process $procName
        }

        # echo ==== _writeArchive
        # echo env(HCISITEDIR) $env(HCISITEDIR)
        # echo thread_process $thread_process
        # echo thread_name $thread_name


        # Building vars
        set siteDir [file split $env(HCISITEDIR)]
        set root [lindex $siteDir 1]
        set archive "__history"
        set site [lindex $siteDir end]
        set fn ""; keylget args ARGS.fn fn
        set suffix "[clock format [clock seconds] -format "%Y%m%d"].msg"

        # Substitute dynamic
        lappend map "%thread%" $thread_name
        set fn [string map $map $fn]

        # Compile the full path
        set filepath [file join / $root $archive $site $thread_process "$fn$suffix"]
        #echo $filepath

        # Make sure the folder exists
        file mkdir [file dirname $filepath]

        # Write file out
        set mychannel [open $filepath a+]
        puts $mychannel $data
        close $mychannel

        lappend dispList "CONTINUE $mh"
        return $dispList
    }
}
}


