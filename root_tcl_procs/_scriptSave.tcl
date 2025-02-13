if 0 {
	About
		
	
	Links
		
	
	Dependencies
		
	
	History
		
	
	Example
		
	
	Change Log:
		
	
	TODO:
		
}
#

proc _scriptSave {script contents} {
	
	# Before we touch it back it up
	if {[file exists $script]} {
		set now [clock format [clock seconds] -format %Y-%m-%d_%H.%M.%S]
		
		set s [file split $script]
		set fn [lindex $s end]
		set path [lrange $s 0 end-1]
		
		file copy $script [file join {*}$path old $fn.$now]
	}
	

	# Write	out the formated file
	set fl [open $script w]
	puts -nonewline $fl [_baseDencode $contents]
	close $fl
}