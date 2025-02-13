if 0 {
    Script:
    tps_ReportTypeFilterAndSave

    Description: Will perform lookup by report type to determine whether or not to send message.
    This proc will also write messages to individual files with a limit of 100 per report type.

    History:
    04/26/2017 -
    -Initial version
}
#

proc tps_ReportTypeFilterAndSave { args } {
    global HciConnName                                  ;# Name of thread
    global env
    global NoteTypesCount

    set mode ""  ; keylget "args" MODE "mode"           ;# Fetch mode
    set ctx ""   ; keylget "args" CONTEXT "ctx"         ;# Fetch tps caller context
    set uargs {} ; keylget "args" ARGS "uargs"          ;# Fetch user-supplied args

    set dispList {}                                     ;# Nothing to return

    # Test test
    set isTest false
    if {[_isNonProd]
        || [_isTTool]} {

        set isTest true
    }


    switch $mode {
        start {
            # set dir $env(HCISITEDIR)/data_out/$HciConnName/Notes
            # set dirs [glob -nocomplain -directory $dir -types d *]
            # set NoteTypesCount ""
            # foreach dr $dirs {
            #     set fls [glob -nocomplain -directory $dr -types f *]
            #     dict append NoteTypesCount [file tail $dr] [llength $fls]
            # }

        }

        run {
            set mh "" ; keylget "args" MSGID "mh"
            set data [msgget $mh]							;# Message data
            set field_delim [string index $data 3]          ;# Field delimiter
            set comp_delim [string index $data 4]           ;# Component delimiter
            set rep_delim [string index $data 5]            ;# Repeat delimiter
            set segList [split $data "\r"]					;# Segments List

            #-------------------------------------------------------
            # Get lookup table to filter on
            #-------------------------------------------------------
            set lkup_tbl ""
            keylget args ARGS.lkup_tbl lkup_tbl
            #set client_id [string tolower $client_id]

            #=========================================================
            # PID
            #=========================================================
            set segIndex [lsearch $segList "PID|*"]
            if {$segIndex>=0} {
                set fldList [split [lindex $segList $segIndex] $field_delim]
                set mrn [lindex [split [lindex $fldList 3] $comp_delim] 0]
            } else {
                # No PID segment, so don't send message.  Write it to NOPID directory.
                set dir $env(HCISITEDIR)/data_out/$HciConnName/Notes/NOPID
                file mkdir $dir
                set fl [open $dir/NOPID.txt a]
                puts $fl $data
                if {[catch {close $fl} err]} {
                    puts "ls command failed: $err"
                }
                lappend dispList "KILL $mh"
                return $dispList
            }

            #=========================================================
            # TXA
            #=========================================================
            set segIndex [lsearch $segList "TXA|*"]
            if {$segIndex>=0} {
                set fldList [split [lindex $segList $segIndex] $field_delim]
                _lextend "fldList" 10

                # Get report type.  This will be used to create top level folders.
                set RptType [string toupper [lindex [split [lindex $fldList 2] $comp_delim] 0]]

                #set sendMsg [tbllookup Steve.tbl $RptType]
                set sendMsg [tbllookup $env(HCISITEDIR)/Tables/$lkup_tbl $RptType]

                if {$sendMsg == "1" } {

                    # Open/Create file
                    set dir $env(HCISITEDIR)/data_out/$HciConnName/Notes/$RptType
                    file mkdir $dir
                    set fl [open $dir/$mrn.txt a]
                    puts $fl $data
                    if {[catch {close $fl} err]} {
                        puts "ls command failed: $err"
                    }

                    # # If file exists, open and append.
                    # if {[file exists $dir/$mrn.txt]} {

                    # } else {
                    #     # If file doesn't exist, create file if less than 100 files exist.
                    #     if {[_dictGet -default 0 $NoteTypesCount] < 100} {
                    #         set dir $env(HCISITEDIR)/data_out/$HciConnName/Notes/$RptType
                    #         file mkdir $dir

                    #         # Save to file
                    #     set fileDetails "$dir/$mrn.txt"
                    #     set fl [open $fileDetails w]
                    #     	puts $fl $data
                    #     	if {[catch {close $fl} err]} {
                    #     	puts "ls command failed: $err"
                    #     }
                    #     dict incr NoteTypesCount $RptType
                    #     }
                    # }

                } else {
                    # Table lookup says do not send
                    lappend dispList "KILL $mh"
                    return $dispList
                }


            } else {
                # No TXA segment, so don't send message.  Write it to NOTXA directory.
                set dir $env(HCISITEDIR)/data_out/$HciConnName/Notes/NOTXA
                file mkdir $dir
                set fl [open $dir/$mrn.txt a]
                puts $fl $data
                if {[catch {close $fl} err]} {
                    puts "ls command failed: $err"
                }
                lappend dispList "KILL $mh"
                return $dispList
            }

            lappend dispList "CONTINUE $mh"
        }

        shutdown {

        }
    }

    return $dispList
}
#