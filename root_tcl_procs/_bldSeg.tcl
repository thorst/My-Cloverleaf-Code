if 0 {
    Name:
    _bldSeg

    Arguments:
    cntr - The number of fields needed to build the segment
    data - The list of data that will make up the segment.
    fldIn - The list of indexes that the data should file into.

    About:
    This proc builds a segment from scratch.  The number of fields is determined by what is sent to it
    in the cntr variable.  The data in the varaible data corresponds to the field index in the variable fldIn.
    For example, the calling proc...
    set cntr 4
    set data [list PV1 5M test]
    set fldIn [list 0 3 4]
    Outcome =  "PV1|||5M|test"

    History:
    2016-06-12
    -initial version
}
proc _bldSeg {cntr data fldIn} {
    set fldDelim "|"
    set lnth [expr [llength $data] - [llength $fldIn]]

    # Create segment.
    for {set x 0} {$x<=$cntr} {incr x} {
        lappend msg [lindex $data [lsearch $fldIn $x]]
    }

    # Relay if there are extra data in either list.
    # This may mean the user isn't getting their expected results.
    switch -regexp -- $lnth {
        ^(-1)$ {
            set msg ""
            set msg "$lnth extra index(s) in fldIn"
        }
        ^(0)$ {
            set msg [join $msg $fldDelim]
        }
        [1-9] {
            set msg "$lnth extra index(s) in data"
        }
    }
    return $msg
}
