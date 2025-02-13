if 0 {
	Param:
	Purpose:
		return a list of sites, according to the server.ini, for this server
		as a tcl list
	
	Exec Count
		0
}
#

proc _siteList {} {
	global env
	
	# Get the data in the server.ini file
	set ini [file join $env(HCIROOT) server server.ini]
	set lineSplit [split [read_file -nonewline $ini] \n]
	set environs [lsearch -inline $lineSplit "environs=*"]
	
	# Loop over the list of sites
	set siteList ""
	foreach fsite [split $environs ";"] {
		lappend siteList [lindex [file split $fsite] end]
	}
	return $siteList;
}
#
