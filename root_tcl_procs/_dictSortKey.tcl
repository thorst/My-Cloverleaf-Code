if 0 {
    Name:
        _dictSortKey
        
    Description:
        Allow you to sort a dictionary by its keys
        Allow any arguments of lsort
    
    Example:
        set d1 [dict create 10 k1 89 k2 1 k3 15 k4 20 k5 100 k6]
        
        #Sort alpha
        puts [_dictSortKey $d1]
        #>> 1 k3 10 k1 100 k6 15 k4 20 k5 89 k2
        
        #Sort numeric
        puts [_dictSortKey $d1 -integer]
        #>> 1 k3 10 k1 15 k4 20 k5 89 k2 100 k6 
        
        #Reverse sort numeric
        puts [_dictSortKey $d1 -integer -decreasing]
        #>> 100 k6 89 k2 20 k5 15 k4 10 k1 1 k3
}
proc _dictSortKey {dict args} {
    #Create essentially a keyed list. A list with sublists
    set lst {}
    dict for {k v} $dict {lappend lst [list $k $v]}
    #puts $lst ;#"{k1 10} {k2 89} {k3 1} {k4 15} {k5 20}"
    
    #Execute the lsort command on the lindex 1 of the sublists
    #Treat any arguments as arguments for the lsort
    #This allows numeric and reverse etc
    #Once executed use concat to rejoin all the sublists back into 
    #  one list, thereby abiding by dict syntax
    return [concat {*}[lsort -index 0 {*}$args $lst]]
    
    #In tcl 8.6 lsort has a new stride param to deal with groups
    #The below command can replace all of the above
    #return [lsort {*}$args -stride 2 -index 0 $dict]
}
