proc _scriptList {{site nosite}} {
	#Get the globals
	global env
	set HCIROOT $env(HCIROOT)
	
	#Determine path to tclIndex
	set dir [file join $HCIROOT tclprocs]
	if {$site!="nosite"} {
		set dir [file join $HCIROOT $site tclprocs]	
	}
	
	set tclIndex [file join $dir tclIndex]
	
	#Read tcl index
	set fl [open $tclIndex]
	set data [read $fl]
	if {[catch {close $fl} err]} {
		puts "ls command failed: $err"
	}
	
	#Eval the file
	eval $data
	
	#Return data
	set scripts ""
	foreach {name path} [array get auto_index] {
		#echo [lindex $path 1]
		set fullPath [lindex $path 1]
		set file [lindex [file split $fullPath] end]
		lappend scripts [dict create \
							name $name \
							path $fullPath \
							file $file
						]
	}
	
	set scripts [_ldictSort $scripts name]
	
	return $scripts
}