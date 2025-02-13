if 0 {
    Name:
        _lremove listName indices
        
    Description:
        Why is tcl missing lremove? IDK. Here is a version that allows
		you to remove an index or list of indexes.
		
		If you would like to remove by value try _lremoveVals.
		
		Read about an extremely edge case bug in the next comment block.
    
    Example:
		
	Pass in NAME of list and modify it directly
		set output [list 1 2 3 20]
		_lremove output 0
		echo $output
		>> 2 3 20
	
	Now I want to remove several indexes
		set output [list 1 2 3 20]
		_lremove output [list 0 1]
		echo $output
		>> 3 20
	
	Pass in Variable and modify it - you then need to set the output
		set output [list 1 2 3 20]
		set output [_lremove $output 0]
		echo $output
		>> 2 3 20
	
	Similarly, even if we pass in varname we can still set the output
		set output [list 1 2 3 20]
		set output [_lremove output 0]
		echo $output
		>> 2 3 20
	
	Change Log
	04-01-2015 Todd Horst
		-Initial version
	04-29-2015
		-Overhauled to remove "remove by value" (split out)
		-Allow input of either varname or var
		-Allow list of indexes to be removed
		-Sort to remove indexes for all you tricksters
		-Ignore if index > llength
	01-29-2020
	    -Allow users to send in "end"
	
	TODO:
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
		set p [_lremove [list u] [list 0 1]]
		echo $u
		echo $p
		>> 3
		>> 3
	
	#2
		set u [list 1 2 3]
		set p [_lremove [list u p p e r] [list 0 1]]
		echo $u
		echo $p
		>> 1 2 3
		>> p e r
	
	#3
		set u [list 1 2 3]
		set u2 [list u]
		set p [_lremove u2 [list 0 1]]
		echo -$u-
		echo -$p-
		echo -$u2-
		>> -1 2 3-
		>> --
		>> --	
}
#

proc _lremove {listName vals} {
	# Try to grab a reference
    catch {upvar $listName list}
    
    # If list is undefined that means they passed the value instead of name
    if {![info exists list]} {set list $listName}

	# Cache the length to bale out if index exceeds
	set len [llength $list]
	
	# Allow users to send in "end", allowed by many l commands
	set end [expr {$len-1}]
	set endI [lsearch $vals "end"]
	if {$endI>=0} {
	    set vals [lreplace $vals $endI $endI $end]
    }
	
	# We have to offset the replace because if they sent in a list
	# thier indexes are continually gowing down 1
	set i 0
	foreach v [lsort -integer $vals] {
		# Check for out of bounds
		if {$v>$len} {
			break
		}
		
		# Figure out the actual position
		set nv [expr {$v-$i}]
		incr i
		
		# Remove it
		set list [lreplace $list $nv $nv]
		
	}
	
	return $list
}
#