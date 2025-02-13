if 0 {
	Name:
	_lextend listName length ?exact?
	listName-	the name or value of a list. name prefered.
	length 	-	the desired length
	exact	-	by default I compensate forp 0 index, send true to get exact length

	Description:
	lset and lreplace require an index exist prior to setting it
	_lextend is a replacement for other_Extend_List
	This script will compensate forp 0 index by adding 1 forp you

	All other list commans do NOT need the index to exist:
	lrange,lindex,linsert,lappend,list,llength,lrepeat,lreverse
	lsearch,lsort

	Read about an extremely edge case bug in the next comment block.

	Example:

	Pass in NAME of list and modify it directly
	set output [list 1 2 3]
	_lextend output 5
	echo $output
	>> 1 2 3 {} {} {}

	Pass in Variable and modify it - you then need to set the output
	set output [list 1 2 3]
	set output [_lextend $output 5]
	echo $output
	>> 1 2 3 {} {} {}

	Similarly, even if we pass in varname we can still set the output
	set output [list 1 2 3]
	set v2 [_lextend output 5]
	echo $v2
	>> 1 2 3 {} {} {}


	Change Log
	04-29-2015 Todd Horst
	-Initial version
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

	#1 - its confused since u is a valid varaible
	set u [list 1 2 3]
	set p [_lextend [list u] 5]
	echo $u
	echo $p
	>> 1 2 3 {} {} {}
	>> 1 2 3 {} {} {}

	#2 - now it knows since there is more than one item
	set u [list 1 2 3]
	set p [_lextend [list u p] 5]
	echo $u
	echo $p
	>> 1 2 3
	>> u p {} {} {} {}

	#3 - passed by name so there is no confusion
	set u [list 1 2 3]
	set u2 [list u]
	set p [_lextend u2 5]
	echo -$u-
	echo -$p-
	echo -$u2-
	>> -1 2 3-
	>> -u {} {} {} {} {}-
	>> -u {} {} {} {} {}-
}
#

if 0 {
	OLD COMMENTS
	# Name:       	other_Extend_List
	# Author:     	Roger
	# Purpose:    	This proc pads a list to the number of elements specified
	#             	(it will not truncate extra elements).
	#
	#             	When trying to set field #n (e.g., using lreplace/) and the list doesn't
	#             	have that many elements, an error occurs. By first doing:
	#                	set mylist [other_Extend_List $myList $n]
	#             	you can then do the lreplace of element n assured that it will succeed.
	#
	# UPoC type: 	other
	#
	# Parameters: 	1. The list to be extended
	#             	2. The minimum number of elements for the returned list.
}
#

proc _lextend {listName len {exact false}} {
	# Try to grab a reference
	catch {upvar $listName list}

	# If list is undefined that means they passed the value instead of name
	if {![info exists list]} {set list $listName}

	# Determine number to add
	set i [expr {$len-[llength $list]}]

	# If they want exactly what they pass in and not +1
	if {!$exact} {incr i;}

	# If we arent at least adding one
	if {$i<1} {return $list;}

	# Overwrite the list with new length

	#rogers original
	#if {$AddToList > 0} {set List "$List [split [string repeat "|" $AddToList] "|"]"}

	#lrepeat cannot repeat empty segments, so i had to call -lreplaceVal
	#set list [concat $list [_lreplaceVal -all [lrepeat $i \x00] \x00 ""]]

	#seemed like a waste to do repeat, split and concat
	#set list [concat $list [split [string repeat "|" $i] "|"]]

	#still seemed like a waste to concat and repeat
	#set list [concat $list [string repeat {{} } $i]]

	#lappend requires list, but append doesnt
	#append list [string repeat { {}} $i]

	#I tried this before and thought it didnt work...
	set list [concat $list [lrepeat $i ""]]

	#extend the list
	return $list
}
