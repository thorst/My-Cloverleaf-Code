if 0 {
    Name:
        _lremoveVals ?options? list removeValues
        
    Description:
        _lremoveVals will remove items from a list if it matches
		the value(s) passed in. You can pass in parameters of
		lsearch to filter more -inline wont work
		
		_lremove removes by index, if thats what you're looking for
		
		Read about an extremely edge case bug in the next comment block.
    
    Example:
	
	Remove empty values
	echo [_lremoveVals $myList "\{\}"]
	
	Pass in NAME of list and modify it directly
	Use lsearch -nocase to remove both tests
	Use list of values to remove
		set u [list 1 2 3 20 TEST test]
		echo [_lremoveVals -nocase $u [list 1 2 test]]
		>> 3 20
	
	Remove everything except values starting in 2
		set u [list 1 2 3 20 TEST test]
		echo [_lremoveVals -not $u 2*]
		>> 2 20

    Realistic example removing report obx segments
        set li [list "MSH|!@#" "PID|TODD" "OBX|1|RP|EWRI" "OBX|2|EWRI"]
        _lremoveVals li "OBX|*|RP*"
        echo $li
        >> MSH|!@# PID|TODD OBX|2|EWRI
	
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
		set p [_lremoveVals [list u] 1]
		echo $u
		echo $p
		>> 2 3
		>> 2 3
	
	#2
		set u [list 1 2 3]
		set p [_lremoveVals [list u p p e r] u]
		echo $u
		echo $p
		>> 1 2 3
		>> p p e r
	
	#3
		set u [list 1 2 3]
		set u2 [list u]
		set p [_lremoveVals u2 u]
		echo -$u-
		echo -$p-
		echo -$u2-
		>> -1 2 3-
		>> --
		>> --	
}
#

proc _lremoveVals {args} {
	# To keep the syntax the same as lsearch
	set listName [lindex $args end-1]
	set vals [lindex $args end]
	set args [lrange $args 0 end-2]
	
	# Try to grab a reference
    catch {upvar $listName list}
    
    # If list is undefined that means they passed the value instead of name
    if {![info exists list]} {set list $listName}
	
	# If they passed not remove it, if they didnt add it
	# We want the oposite because we are removing items
	set hasNot [lsearch $args "-not"]
	if {$hasNot>=0} {
		_lremove args $hasNot
	}
	#if {$hasNot>=0} {
	#	set hasNot true
	#} else {
	#	set hasNot false
	#}
	
	# Remove each value they send in
	# You may ask "why the two lists"
	# I tried to do the inverse on -not depending on what they passed in
	# That works fine if they dont pass in a -not.
	# If they do pass in -not, it would essentially return empty, or close
	# to, since it would canabalize on itself
	set notlist ""
	foreach v $vals {
		
		# Append to the NOT list all the ones that match this elimination
		lappend notlist {*}[lsearch {*}$args -all -inline $list $v]
		
		# Get everything but the ones that need eliminated
		# This should get progressively faster due to the list
		# continually reducing
		# 
		# We COULD only do this one or the one above, but if we
		# do that duplicates might happen because the source
		# list keeps on staying the same.
		set list [lsearch {*}$args -all -not -inline $list $v]
	
	}
	
	# If the user passed in not, send them the inverse
	if {$hasNot>=0} {
		set list $notlist
	}
	
	return $list
}

