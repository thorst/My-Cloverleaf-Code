if 0 {
    Script:
    _BlockLargeMsg

    Description:

    History:
    05/11/2017 -
    -Initial version
}
#

proc _BlockLargeMsg { args } {
    global HciConnName                                  ;# Name of thread
    global env

    set mode ""  ; keylget "args" MODE "mode"           ;# Fetch mode
    set ctx ""   ; keylget "args" CONTEXT "ctx"         ;# Fetch tps caller context
    set uargs {} ; keylget "args" ARGS "uargs"          ;# Fetch user-supplied args

    set dispList {}                                     ;# Nothing to return



    switch $mode {
        start {}

        run {
            set mh "" ; keylget "args" MSGID "mh"
            set data [msgget $mh]                            ;# Message data

            if {[string length $data] > 200000} {
                set f "$env(HCIROOT)/$HciConnName.LargeMsg.txt"
                set fl [open $f a]
                puts $fl $data
                if {[catch {close $fl} err]} {}

                lappend dispList "KILL $mh"
                return $dispList
            }
            lappend dispList "CONTINUE $mh"
        }

        shutdown {}
    }

    return $dispList
}
#