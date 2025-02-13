if 0 {
	Given a list of threads and a site, add the error keys
	then return the new list of threads.
	
	We want them as 2 keys to make json serializing easier
}
proc _threadErrors {site threads} {
	global env

	set errors [_dbListMin $site e]
	
	set idx -1
    foreach thread $threads {
		# Get name from dictionary
		set Name [dict get $thread Name]
		
		# Try to get this threads errors
		set error [_dictGet $errors $Name]
		set DataError [_dictGet $error Data]
		set ReplyError [_dictGet $error Reply]
		
		#If nothing is returned convert to 0
		if {$DataError==""} {set DataError 0;}
		if {$ReplyError==""} {set ReplyError 0;}
		
		# Add them or empty string
		dict append thread DataError $DataError
		dict append thread ReplyError $ReplyError
		
		# Overwrite thread 
		lset threads [incr idx] $thread
	}
	
	return $threads
}

