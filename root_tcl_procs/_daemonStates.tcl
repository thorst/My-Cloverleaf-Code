if 0 {
	Name
	_daemonStates site ?opts? ?args?

	About
	Get the state of site daemons with pids

	Playground
	set state [_daemonStates physician]
	set state [_daemonStates physician [dict create includeProcessCount true]]

	Returns:
	lock {state true pid 2179} monitor {state true pid 2186}

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
	09/22/2017 - TMH
	-Updated _daemonStates to return a dictionary with pid instead of just state
	-Terse if for shorter code
	10/04/2017 - TMH
	-Include options optional parameter, ala jQuery
}
proc _daemonStates {site {opts {}} args} {
	# Initialize options
	set opts [dict merge [dict create \
		includeProcessCount false \
		] $opts]

	# Initialize return obj
	set mon ""
	set lock ""

	# Ensure correct site obvi
	_siteSet $site

	# get output
	set procState [split [exec hcisitectl] \n]

	# get line
	set Lockmgr [lindex $procState 1]
	set hcimonitord [lindex $procState 2]

	# get pids, if last word is running its actually part of "not running"
	set lockPid [lindex $Lockmgr end]
	set lockPid [expr {$lockPid=="running" ? 0 : $lockPid}]
	dict set lock pid $lockPid

	set monPid [lindex $hcimonitord end]
	set monPid [expr {$monPid=="running" ? 0 : $monPid}]
	dict set mon pid $monPid

	# get state
	set lockState [lindex [split [string range $Lockmgr [string first "is" $Lockmgr] end] " "] 1]
	set lockState [expr {$lockState=="NOT" ? false : true}]
	dict set lock state $lockState

	set monState [lindex [split [string range $hcimonitord [string first "is" $hcimonitord] end] " "] 1]
	set monState [expr {$monState=="NOT" ? false : true}]
	dict set mon state $monState

	# includeProcessCount
	if {[dict get $opts includeProcessCount]} {
		dict set mon processCount [llength [_pidSearch [dict create term "hcimonitord -S $site$"]]]
		dict set lock processCount [llength [_pidSearch [dict create term "lm .*$site "]]]
	}

	return [dict create \
		lock $lock \
		monitor $mon
	]
}