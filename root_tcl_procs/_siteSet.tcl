if 0 {
	Name:
		_siteSet sitename ?force?
		
		sitename - String - Name of site to change to
		force - Bool - Change even if we are already there
	
	Purpose:
		switch to a site
	
	Exec Count
		1
	
	Changes
	2015-05-13 Todd Horst
		-Added check to see if you are already in this site
		-You can bypass the check by optionally sending in true
	2015-05-14 Todd Horst
		-Cache output of hcisetenv instead of execing always
	2016-09-13 Todd Horst
	    -Caching had a negative side effect. The globals changed between versions
	    and the cache was never cleared. In hindsight im not sure how much better this would be
	    so I simply removed it.
}
#

proc _siteSet {sitename {force false}} {
	global env tcl_platform
	
	#If the current site is already 
	if {$env(HCISITE)==$sitename && !$force} {
		return 1
	}
	
	#Make sure directory exists
	file mkdir [file join $env(HCIROOT) cache]

	#Check to see if this was already output before
	#If not get and cache it
	set command ""
# 	set fname [file join $env(HCIROOT) cache site.set.$sitename.txt]
# 	if {[file exists $fname]} {
		
# 		#Get Cache
# 		set fl [open $fname]
# 		set command [read $fl]
# 		if {[catch {close $fl} err]} {
# 			puts "ls command failed: $err"
# 		}
		
# 	} else {
		
		#Get command
		set Platform  $tcl_platform(platform)
		set command "$env(HCIROOT)/sbin/hcisetenv -site tcl $sitename"
		
		#Run command
		if {$Platform=="windows"} {
			set command [exec cmd /C $command]
		} else {
			set command [exec ksh -c $command]
		}
	
		#Cache it out
# 		set fl [open $fname w]
# 		puts -nonewline $fl $command
# 		if {[catch {close $fl} err]} {
# 			puts "ls command failed: $err"
# 		}
		
	#}
	
	
	eval $command
	
	
	return 1
}
#

