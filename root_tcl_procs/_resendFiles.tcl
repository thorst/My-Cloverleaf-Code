proc _resendFiles {} {
	global env
	set files [glob -nocomplain -directory [file join $env(HCIROOT) data_resend] "*"]
	
	set records ""
	foreach file $files {
		lappend records [dict create \
					Name [lindex [file split $file] end] \
					Path $file
				]
	}
	return $records
}
#_dbList physician e