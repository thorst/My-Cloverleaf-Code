if 0 {
	Name
	_daemonState site

	About
	Get the state of a process

	Playground
	set state [_daemonState physician]

	Returns:
	{lock true monitor true}

	Dependencies
	_siteSet

	Exec Count
	1

	Exec
	[hci@ ~]$ hcisitectl
	Lockmgr    is running on pid 18831
	hcimonitord is running on pid 18826
	[hci@ ~]$ hcisitectl
	Lockmgr    is NOT running
	hcimonitord is NOT running

	Change Log
	2018-12-11 - TMH
	-Added windows compatibility
}
proc _daemonState {site} {
	global env tcl_platform
	# Get the platform
	set Platform $tcl_platform(platform)
	_siteSet $site

	# get output
	set procState ""
	if {$Platform=="windows"} {
		set procState [split [exec cmd /C hcisitectl] \n]
	} else {
		set procState [split [exec hcisitectl] \n]
	}


	# get line
	set Lockmgr [lindex $procState 1]
	set hcimonitord [lindex $procState 2]

	# get state
	set lockState [lindex [split [string range $Lockmgr [string first "is" $Lockmgr] end] " "] 1]
	set monState [lindex [split [string range $hcimonitord [string first "is" $hcimonitord] end] " "] 1]

	if {$lockState=="NOT"} {
		set lockState false
	} else {
		set lockState true
	}

	if {$monState=="NOT"} {
		set monState false
	} else {
		set monState true
	}

	return [dict create \
		lock $lockState \
		monitor $monState
	]
}