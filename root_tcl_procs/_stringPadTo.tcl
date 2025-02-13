if 0 {
	Purpose:
		Prefix or suffix a string with a character
		to a certain length
	
	Playground:
		puts -[_stringPadTo "12346" 10 "0"]-
		>> -0000012346-
		
		puts -[_stringPadTo "12346" 10 "0" end]-
		>> -1234600000-
		
		puts -[_stringPadTo "123456" 2]-
		>> -123456-
		
		puts -[_stringPadTo "123456" 10 "m" "rear"]-
		>> -123456mmmm-
	
	Change Log:
	2015-04-28 Todd Horst
		Initial version
		
	TODO:
}
#

proc _stringPadTo {str {num 1} {char " "} {side front} } {
	#format is snazzy, but it only works with 0 or spaces pads
	#switch $side {
	#  beginning - front - left - start {return [format %*$char*$num\s $str]}
	#  back - rear - right - end {return [format "%-$char$num\s" $str]}
	#  default {return $str}
	#}
	set i [expr {$num-[string length $str]}]
	if {$i<0} {return $str}
	return [_stringPad $str $i $char $side]
}
#