proc _fixLineEndings {script {options ""}} {

	set options [dict merge [dict create \
	    isBlob false
	] $options]
	

		
	# They passed in a based blob instead of a filename
	set data ""
	if {[dict exists $options "isBlob"] && [dict get $options "isBlob"]} {

		set data [_baseDencode $script]
	} else {
		# File needs to exist
		if {![file exists $script]} {
			return
		}
		
		# Before we touch it back it up
		set now [clock format [clock seconds] -format %Y-%m-%d_%H.%M.%S]
	
		set s [file split $script]
		
		set fn [lindex $s end]
		set path [lrange $s 0 end-1]
	
		file mkdir [file join {*}$path old]
		file copy $script [file join {*}$path old $fn.$now]
		
		
		# Read file in
		set fl [open $script]
		set data [read $fl]
		close $fl
	}

    # Replace <cr><lf> sequences with <nl> only
	set data [string map {\r\n \n} $data]

	if {[dict exists $options "isBlob"] && [dict get $options "isBlob"]} {
		return [_baseEncode $data]
	} else {
		# Write	out the formated file
		set fl [open $script w]
		puts -nonewline $fl $data
		close $fl
		return true
	}	
}
