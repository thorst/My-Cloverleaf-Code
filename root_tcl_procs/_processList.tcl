if 0 {
	Name
		_processList site
	
	About
		Return a list of processes in a site
	
	Sandbox
		set processList [_processList $site]
	
	Exec Count
		0
}
#

proc _processList {site} {
    global env
    
    # Get this sites directory/ netconfig
    set SiteDir [file join $env(HCIROOT) $site]
    set nc "$SiteDir/NetConfig"
    netcfgLoad $nc                                                    ;#Load net config
    
    # Read net config
    set fl [open $nc]
    set data [split [read $fl] \n]
    close $fl
    
    # Get a list of the protocols
    set processList ""
    foreach line [lsearch -all -inline $data "process * \{"] {
        lappend processList [lindex [split $line " "] 1]
    }
    
    return $processList
}
#