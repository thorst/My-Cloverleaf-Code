if 0 {
    Descrition:
    Easily/Efficiently renumber specified segments
    
    Author:
    Todd Horst
    
    Example:
    #set segList [other_RenumberSegs $segList [list nte]]
    _segRenumber segList [list nte]
    _segRenumber segList nte
    
    Change Log:
    07/09/2013 - Initial
    05/04/2015 - Rewrite for _ lib
}
proc _segRenumber {segList segs} {
    # Try to grab a reference
    catch {upvar $segList list}
    
    # If list is undefined that means they passed the value instead of name
    if {![info exists list]} {set list $segList}
    
    # Loop over each segment type they send in
    set field_delim [string index $list 4]
    foreach curseg [string toupper $segs] {
        set cntr 1
        
        # Renumber its fields
        foreach seg [lsearch -all $list "$curseg|*"] {
            set fldList [split [lindex $list $seg] $field_delim]
            _lextend fldList 1
            lset fldList 1 $cntr
            incr cntr
            lset list $seg [join $fldList $field_delim]
        }
    }
    return $list
}