if 0 {
    Author: Todd Horst
    Change Log:
        2016-04-06 TMH
            -Allow you to send in path
            -HCIROOT substitution
}
proc _procMkTclIndex {{site nosite}} {
	global env
	set HCIROOT $env(HCIROOT)
	set site [string map "\$HCIROOT $HCIROOT" $site]
	
	#determine path
	if {$site=="nosite"} {
		set path [file join $HCIROOT tclprocs]
	} elseif {[file exists $site]} {
	    set path $site
	} else {
	    set path [file join $HCIROOT $site tclprocs]
	}
	
	#get there
	cd $path

	#execute mktclindex
	set output [exec mktclindex]

	return 1
}





