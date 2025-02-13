if 0 {
	Param:
	    str     - string you wish to split
	    chunk   - The character size of each chunk
	
	Purpose:
		Split a string into chunks.
		
		This could be good for splitting a long nte into smaller ntes
		
	Example:
	    echo [_stringChunk "1234567890" 2]
	    >> 12 34 56 78 90
	    
	TODO:
	    Optionally honor words (loop back to spaces), this may work better
	    as a seperate proc due to the additional code
}
#

proc _stringChunk {str chunk} {
	set l "" 		;#list of chunks
	incr chunk -1	;#They say they want say 75 characters, that means range 0-74
	for {set x 0} {$x<[string length $str]} {incr x} {
		lappend l [string range $str $x [incr x $chunk]]
	}
	return $l
}
#

