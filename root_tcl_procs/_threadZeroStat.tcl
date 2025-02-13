if 0 {

	About:
	Easily zero thread a thread

	Playground:
	echo [_threadZeroStat physician thread] ;# Zero
	echo [_threadZeroStat physician thread true] ;# Zero , but keep times
	echo [_threadZeroStat physician -Z] ;# Zero all, ignore ?keepTimes?
	echo [_threadZeroStat physician -X] ;# Zero all, but keep times, ignore ?keepTimes?

	Changes:


}
proc _threadZeroStat {site thread {keepTimes false}} {
	global env tcl_platform
	set Platform $tcl_platform(platform);	#Get the platform
	set HCIROOT $env(HCIROOT)

	# set the site
	_siteSet $site

	# issue the command
	if {$thread=="-Z" || $thread=="-X"} {
		set cmd "hcimsiutil $thread"
	} elseif {$keepTimes} {
		set cmd "hcimsiutil -xt $thread"
	} else {
		set cmd "hcimsiutil -zt $thread"
	}


	if {$Platform=="windows"} {
		set cmd $::env(ComSpec);				#Get path to cmd
		set output [exec $cmd /C $cmd]
	} else {
		set output [exec ksh -c $cmd]
	}

	return
}



