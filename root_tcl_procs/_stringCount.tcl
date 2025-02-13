if 0 {
	Purpose:
		Count the occurences of char in str
	
	Playground:
		puts [_stringPad "Mississippi" i]
		>> 4
	
	Change Log:
	2015-04-01 Todd Horst
		Initial version
	2017-04-25 Todd Horst
	    Allows counting strings not just char
		
	TODO:
	-Specify case sensitive
}
#

proc _stringCount {str char {needleIsString false}} {
	if {$needleIsString} {
	    return [expr [llength [_split $str $char]] -1]
	} else {
	    return [expr [llength [split $str $char]] -1]
	}
}
#
