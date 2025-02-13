if 0 {
	Purpose:
		Prefix or suffix with a character
		a specific number of times
	
	Playground:
		puts [_stringPad "My String" 4]
		>> "    My String"
		puts [_stringPad "12346" 4 "0" end]
		>> "123460000"
	
	Change Log:
	2015-04-01 Todd Horst
		Initial version
		
	TODO:
}
#

proc _stringPad {str {num 1} {char " "} {side front} } {
	set pad [string repeat $char $num]
	switch $side {
	  beginning - front - left - start {return $pad$str}
	  back - rear - right - end {return $str$pad}
	  default {return $str}
	}
}
#
