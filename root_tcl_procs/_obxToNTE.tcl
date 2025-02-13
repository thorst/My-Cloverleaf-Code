if 0 {
    _obxToNTE
    This is the successor to , which was a little too invasive and
    caused some report errors. In defense we were working with a limited set of
    test data. Some issues were:
    -missing obx.1
    -nte's without complete data in 3
    -gaps in segList
    -unneed nte at top of path reports


    Micros
    need a targeted approach where the obx's are only converted to nte if they
    dont have obr.3 valued
    Path
    seem to all need to be converted to nte

    Change Log:
    10/27/2017 - TMH
    -Initial version
}

proc _obxToNTE {segList} {
    ############################################
    # Clean empty segs
    ############################################
    set data [string trim [join $segList \r]]
    set segList [split $data "\r"]

    ############################################
    # Delimeters
    ############################################
    set field_delim [string index $segList 4]          ;# Field delimiter
    set comp_delim [string index $segList 5]           ;# Component delimiter
    set rep_delim [string index $segList 6]

    ############################################
    # OBR
    ############################################
    set segIndex [lsearch $segList "OBR|*"]
    set obr4 ""
    set isPath ""
    if {$segIndex>=0} {
        set fldList [split [lindex $segList $segIndex] $field_delim]
        set obr4 [lindex $fldList 4]

        set obr24 [lindex [split [lindex $fldList 24] ","] 0] ;# This cut seems fragile
        set isPath [expr {$obr24=="Path"}]
    }

    ############################################
    # OBX
    ############################################
    set obxs [lsearch -all $segList "OBX|*"]
    set first true
    set offset 0
    set zpl ""
    set prev3 ""
    foreach segIndex $obxs {
        set segIndex [expr {$segIndex+$offset}]                         ;# If they padded out
        set fldList [split [lindex $segList $segIndex] $field_delim]
        _lextend "fldList" 5

        # Anytime obx.3 is blank convert it to an NTE
        # This is prolly a micro
        if {[string trim [lindex $fldList 3]]=="" || $isPath} {

            # If this is the first one, keep a "see note" obx
            if {$first} {
                # House keeping
                set first false
                incr offset

                # Copy obx, modify it, and insert it back in
                set tmpFldList $fldList
                lset tmpFldList 3 $obr4
                lset tmpFldList 5 "See Note"
                set segList [linsert $segList $segIndex [join $tmpFldList $field_delim]]

                # Make sure we maintain our position
                incr segIndex

                # Grab the performing lab information
                set zpl [lrange $fldList 23 end]
            }

            # For Path we need to use the 3rd comp for headers
            set obx32 [lindex [split [lindex $fldList 3] $comp_delim] 1]

            # Insert a spacer, if its not the first secton header
            if {$isPath && $prev3!=$obx32 && $prev3 != ""} {
                set segList [linsert $segList $segIndex [join [_lextend "NTE" 3] $field_delim]]
                incr offset
                incr segIndex
            }

            # Insert the section header
            if {$isPath && $prev3!=$obx32} {
                set prev3 $obx32
                set segList [linsert $segList $segIndex [join [list "NTE" "" "" "$obx32"] $field_delim]]
                incr offset
                incr segIndex
            }

            # Convert to nte
            lset fldList 0 "NTE"
            lset fldList 2 ""
            lset fldList 3 [lindex $fldList 5]
            set fldList [lrange $fldList 0 3]
        }

        # Commit changes
        lset segList $segIndex [join $fldList $field_delim]
    }

    ############################################
    # ZPL
    ############################################
    if {$zpl!=""} {
        set zpl [list "ZPL" {*}$zpl]
        lappend segList [join $zpl $field_delim]
    }

    ############################################
    # Renumber and remove segs
    ############################################
    _lremoveVals "segList" [list "TQ1|*"]
    _segRenumber "segList" [list obx nte]

    ############################################
    # Return
    ############################################
    return $segList
}