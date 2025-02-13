if 0 {
    Name:
        _lreplaceVal ?options? listName pattern newValue
        
    Description:
		_lreplaceVal replaces items in list with new value
		
        lreplace replaces by index
		
		Read about an extremely edge case bug in the next comment block.
    
    Example:
	
	Pass in NAME of list and modify it directly
		set output [list 1 1 2 3 20]
		_lreplaceVal output 1 2
		echo $output
		>> 2 1 2 3 20
	
	Pass in lsearch param of -all
		set output [list 1 1 2 3 20]
		_lreplaceVal -all output 1 2
		echo $output
		>> 2 2 2 3 20
	
	Replace by value with wildcar and -all
		set output [list 1 1 2 3 20]
		echo [_lreplaceVal -all output "2*" true]
		>> 1 1 true 3 true
	
}
if 0 {
	A little background:
	lset 	- INPUT is varname, OUTPUT is both "uplevel set var" AND return
	lrepalce- INPUT is var, OUTPUT is return
	
	I wanted my "l" procs to have input of both var and varname, and output
	of both "uplevel" and return. Because of this there is a potential extremely
	edge case issue. So test your script. See example of this below. A simple
	way to avoid it is to ALWAYS pass in the varname.
		
	EXTREMELY EDGE CASE ISSUE
	Reference the examples below. In #1 Since u variable exists, even
	though its passing in a list it thinks you want to use the $u list.
	
	All criteria must happen for you to hit the bug
	1. You are passing in a list value instead of a variable name
	2. Your list contains 1 item
	3. That 1 item in your list is the same name as a variable
	
	#1
		set u [list 1 2 3]
		set p [_lreplaceVal [list u] 1 2]
		echo $u
		echo $p
		>> 2 2 3
		>> 2 2 3
	
	#2
		set u [list 1 2 3]
		set p [_lreplaceVal [list u p p 1] 1 2]
		echo $u
		echo $p
		>> 1 2 3
		>> u p p 2
	
	#3
		set u [list 1 2 3]
		set u2 [list u]
		set p [_lreplaceVal u2 u 2]
		echo -$u-
		echo -$p-
		echo -$u2-
		>> -1 2 3-
		>> -2-
		>> -2-	
}
#

proc _lreplaceVal {args} {
	
	# To keep the syntax the same as lsearch
	set listName [lindex $args end-2]
	set val [lindex $args end-1]
	set newval [lindex $args end]
	set args [lrange $args 0 end-3]
	
	# Try to grab a reference
    catch {upvar $listName list}
    
    # If list is undefined that means they passed the value instead of name
    if {![info exists list]} {set list $listName}
	
	# Get a list of indexes that match the pattern
	foreach v [lsearch {*}$args $list $val] {
		if {$v==-1} {break;}
		lset list $v $newval
	}
	
	return $list
}