if 0 {
	We need to create a list of threads to ignore on the monitor
	by default
}
proc _threadIgnored {} {
	global env
	global HciConnName
	if {![info exists HciConnName]} {
		set HciConnName ""
	}
	set HCIROOT $env(HCIROOT)

	#Define Settings
	set conf(server) ""
	set conf(user) ""
	set conf(password) ""
	set conf(inengine) false
	set conf(TestInterface) N;
	set conf(isTest) false;

	if {[string match "*test*" $env(HCIROOT)]
		|| $HciConnName=="TEST"} {

		set conf(isTest) true;
		set conf(TestInterface) Y;
	}

	#Define the engine
	set engine "CL[string toupper [_serverType]]2"
	if {$engine==""} {set engine "QDX";}

	#Query depends on env
	set query "SELECT * \
		FROM Integration.dbo.IntMonInterfaceList \
		where engine = '$engine' \
		and TestInterface = '$conf(TestInterface)' \
		and DisplayforOthers = 'N' \
		order by site, InterfaceName, Process";

	#Define the request
	set request1(settings) "conf"
	set request1(query) $query
	set request1(close_handle) false

	#If the query executed successfully
	set threads ""
	if {[odbc3_exec "request1"]} {

		#Process request
		while {[odbc3_fetch "request1"]} {
			#echo $request1(col3)  $request1(col1);
			#if {$request1(col7)==""} {continue;}
			lappend threads [dict create \
				Name $request1(col2) \
				Site $request1(col4)]
		}
	}

	#Destroy the connection
	odbc3_destroy "conf"

	set threadList [jCompile {list dict} $threads]

	set cacheDetails "$HCIROOT/cache/threads.ignored.txt"
	set cache [open $cacheDetails w]
	puts $cache [jRender [jObject \
		cached [clock format [clock seconds] -format "%m/%d/%Y %H:%M:%S"] \
		threads $threadList
	]]
	#
	if {[catch {close $cache} err]} {
		puts "ls command failed: $err"
	}


}