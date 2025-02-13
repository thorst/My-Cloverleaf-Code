if 0 {
    Name:
        _dictSortVal
        
    Description:
        Allow you to sort a dictionary by its values
        Allow any arguments of lsort
    
    Example:
        set d1 [dict create k1 10 k2 89 k3 1 k4 15 k5 20 k6 100]
        
        #Sort alpha
        puts [_dictSortVal $d1]
        #>> k3 1 k1 10 k6 100 k4 15 k5 20 k2 89
        
        #Sort numeric
        puts [_dictSortVal $d1 -integer]
        #>> k3 1 k1 10 k4 15 k5 20 k2 89 k6 100
        
        #Reverse sort numeric
        puts [_dictSortVal $d1 -integer -decreasing]
        #>> k6 100 k2 89 k5 20 k4 15 k1 10 k3 1
}
proc _dictSortVal {dict args} {
    #Create essentially a keyed list. A list with sublists
    set lst {}
    dict for {k v} $dict {lappend lst [list $k $v]}
    #puts $lst ;#"{k1 10} {k2 89} {k3 1} {k4 15} {k5 20}"
    
    #Execute the lsort command on the lindex 1 of the sublists
    #Treat any arguments as arguments for the lsort
    #This allows numeric and reverse etc
    #Once executed use concat to rejoin all the sublists back into 
    #  one list, thereby abiding by dict syntax
    return [concat {*}[lsort -index 1 {*}$args $lst]]
    
    #In tcl 8.6 lsort has a new stride param to deal with groups
    #The below command can replace all of the above
    #return [lsort {*}$args -stride 2 -index 1 $dict]
}
