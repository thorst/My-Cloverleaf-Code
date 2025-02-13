if 0 {
	Author:
		Todd Horst
		
    About:
        _set is used to set multiple variables at one shot
        
    Example:
        _set {i1 i2 i3 i4 i5} {4 5 6}  ;#i1=4, i2=5, i3=6, i4&i5=""
        _set {i1 i2 i3 i4 i5} {5} true ;#All variables =5
        _set {i1 i2 i3 i4 i5}          ;#All variables =""
        
    Param List:
        keys-   an array of keys that will be the names of your variables
        values- an array of values that will be assigned to listed variables
        repeat- repeats the last value for keys that would have otherwise been assigned "" due to lack of values
        
    Returns:
        String- Empty
        
    History:
        2016-03-28 TMH - Renamed from old other_Set
}
proc _set {keys {values ""} {repeat false}} {
    for {set x 0} {$x<[llength $keys]} {incr x} {
        if {[llength $values]==0} {                                     ;#If values are blank, set everything to blank
            uplevel "set [lindex $keys $x] \"\""
        } elseif {$x >= [llength $values] && $repeat} {                 ;#If there are more keys than values and they want to repeat, assign the last provided value
            uplevel "set [lindex $keys $x] \"[lindex $values end]\""
        } else {                                                        ;#This key has a matching value so send it
            uplevel "set [lindex $keys $x] \"[lindex $values $x]\""
        } 
    }
}


