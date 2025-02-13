if 0 {
	Name
	_daemonStateAll

	About
	Get the state of all daemons in all sites

	Playground
	set states [_daemonStateAll]

	Returns:

	Exec
	[hci@ ~]$ hcisitectl
	Lockmgr    is running on pid 18831
	hcimonitord is running on pid 18826
	[hci@ ~]$ hcisitectl
	Lockmgr    is NOT running
	hcimonitord is NOT running
}
proc _daemonStateAll {} {

	set allState ""
	set sites [_siteList]
	foreach site $sites {
		set state [_daemonState $site]
		lappend allState [dict create \
			site $site \
			lock [dict get $state lock] \
			monitor [dict get $state monitor]]
	}
	return $allState
}