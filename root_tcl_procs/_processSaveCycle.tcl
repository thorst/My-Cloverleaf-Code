if 0 {
	get the state of a process
	
	Returns:
		* running
		* dead
		
	hcicmd -t d -s $site -c "psummary $process"
	Response:
	psummary {helloworld running {Started at Fri Feb 27 14:05:10 2015}}
	Response:
	psummary {helloworld dead {Normal exit at Tue Mar 10 13:07:16 2015}}
}
proc _processSaveCycle {site process} {
	
	set procState [exec hcicmd -s $site -p $process -c ". output_cycle"]
	set procState [lrange $procState 1 end]
	
	set ret 0
	if {$procState=="Log files cycled"} {
		set ret 1
	}
	return $ret
}
#
#echo [_processSaveCycle physician CSCOUT]