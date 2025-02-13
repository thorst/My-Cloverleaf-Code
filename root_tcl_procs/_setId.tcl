if 0 {
    Name:
    _setId

    Arguments:
    segList should be the whole message.
    seg is the segment you want to set id. I.e., OBX.
    cntr is the number you want to start with.

    About:


    History:
    2018-04-04
    -initial version
}
proc _setId {segList seg cntr {fldDelim "|"}} {
    set index 0
    foreach x $segList {
        if {[string equal [string range $x 0 2] [string toupper $seg]]} {
            set flds [lreplace [split $x $fldDelim] 1 1 $cntr]
            lset segList $index [join $flds $fldDelim]
            incr cntr
        }
        incr index
    }
    return $segList
}
