if 0 {
    Name:
        _ldictSort
        
    Description:
        Allow you to sort a list of dictionary by a key
        Allow any arguments of lsort
    
    Example:
        lappend a [dict create idx 2 row 3 name cool]
        lappend a [dict create idx 1 row 4 name adam]
        lappend a [dict create idx 10 row 5 name baby]
        
        #Sort name alpha
        puts [_ldictSort $a name]
        #>> {idx 1 row 4 name adam} {idx 10 row 5 name baby} {idx 2 row 3 name cool}
        
        #Sort numeric field by alpha
        puts [_ldictSort $a idx]
        #>> {idx 1 row 4 name adam} {idx 10 row 5 name baby} {idx 2 row 3 name cool}
        
        #Reverse sort numeric
        puts [_ldictSort $a idx -integer -decreasing]
        #>> {idx 10 row 5 name baby} {idx 2 row 3 name cool} {idx 1 row 4 name adam}
		
		#Dictionary sort should probably be default. It will convert pieces of a string
		#to integer if its an integer value
		#http://www.tcl.tk/man/tcl8.5/TclCmd/lsort.htm#M6
		#This sorts by mulitple keys, both integer, so
		#instead of sending in -integer send in -dictionary sicne we seperate
		#values with and underscore
		puts [_ldictSort $a [list idx row] -dictionary]
		#>> {idx 1 row 4 name adam} {idx 2 row 3 name cool} {idx 10 row 5 name baby}
}
proc _ldictSort {ld lk args} {
    #Create essentially a keyed list. A list with sublists
    #Key is the values they want to sort on, value is dict
    set lst {}
    foreach d $ld {
		set vals ""
		foreach keys $lk {
			lappend vals [dict get $d $keys]
		}
		lappend lst [list [join $vals "_"] $d]
	}
    #>> {adam {idx 1 row 4 name adam}} {baby {idx 10 row 5 name baby}} {cool {idx 2 row 3 name cool}} 
    
    #Execute the lsort command on the lindex 0 of the sublists
    #  Treat any arguments as arguments for the lsort
    #  This allows numeric and reverse etc
    #Concat to rejoin all the sublists back into one list
    #Then using dict values we get an ordered list of the dicts
    return [dict values [concat {*}[lsort -index 0 {*}$args $lst]]]
}