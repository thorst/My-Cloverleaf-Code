if 0 {

	About:
	Blindly overwrite the cache with a value(s)
	Return dictionary if it found the thread and overwrote values otherwise false

	Playground:
	echo [_threadOverwriteCache physician CSCOUT  [dict create Alive true]]

	Changes:
	2015-04-20 Todd Horst
	- Initial version written a couple weeks back
	- Tweak to now take dictionary of values and not just status
	2015-04-23 Todd Horst
	- Now return false OR dict if successful

}
proc _threadOverwriteCache {site process thread values} {
	global env
	set HCIROOT $env(HCIROOT)
	set cacheDetails "$HCIROOT/cache/threads.details.txt"

	#read in
	set fl [open $cacheDetails]
	set data [read $fl]
	if {[catch {close $fl} err]} {
		puts "ls command failed: $err"
	}

	#parse
	set JSON [jParse $data]
	set threadDict [dict get $JSON threads]

	#update
	set success false
	set i 0
	set newRecord ""
	foreach curthread $threadDict {
		set tname [dict get $curthread Name]
		set tsite [dict get $curthread Site]
		set tprocess [dict get $curthread Process]


		if {$tname==$thread && $tsite==$site && $tprocess==$process} {
			set success true
			set newRecord [dict merge $curthread $values]
			lset threadDict $i $newRecord
			break
		}
		incr i
	}

	if {$success==false} {
		return false
	}

	#compile
	dict set JSON threads $threadDict
	set JSON [jCompile {dict threads {list {dict DataError number Alive bool ReplyError number MsgOut number MsgIn number Pending number * string}} successful bool totalthreads number totalsites number executionMS number executionAvgMS number * string} $JSON]


	#overwrite
	set cache [open $cacheDetails w]
	puts $cache [jRender $JSON]
	if {[catch {close $cache} err]} {
		puts "ls command failed: $err"
	}

	return $newRecord
}
