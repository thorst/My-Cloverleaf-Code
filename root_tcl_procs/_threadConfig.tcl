if 0 {
    Returns a threads config given site and threadname
}
proc _threadConfig {site thread} {
    global env
    set SiteDir [file join $env(HCIROOT) $site]
	set nc "$SiteDir/NetConfig"
	netcfgLoad $nc
	set connData [netcfgGetConnData $thread]
	set PROTOCOL [_keylget connData PROTOCOL]
	#echo $PROTOCOL
	#echo $connData
	
	return [dict create process [_keylget connData PROCESSNAME] ibdir [_keylget PROTOCOL IBDIR]]
}
