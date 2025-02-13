proc _scriptSearch {term} {

	global env
	set HCIROOT $env(HCIROOT)

	#if there is an empty result set, return empty string

	set exErr [catch {exec ksh -c "grep -inZ '$term' $HCIROOT/usercmds/*.tcl $HCIROOT/tclprocs/*.tcl $HCIROOT/*/tclprocs/*.tcl $HCIROOT/server/tomcat/cloverapps//api/*.tcl"} output]

	if {$exErr==1} {
		return "";
	}

	# get a dictionary with a key of the file, value of list of lines
	set found ""
	foreach line [split $output \n] {
		set sp [split $line \x0]
		set line [lindex $sp 1]
		set i [string first ":" $line]
		set number [string range $line 0 [expr $i-1]]
		set result [string trim [string range $line [expr $i+1] end]]

		# if this file already exists, get existing lines
		set existing ""
		if {[dict exists $found [lindex $sp 0]]} {
			set existing [dict get $found [lindex $sp 0]]
		}

		# add the lines
		lappend existing [dict create \
			line $number \
			value $result
		]

		# commit the new object
		dict set found [lindex $sp 0] $existing

	}

	#convert ths to an ideal json object (list of results)
	set result ""
	dict for {k v} $found {

		#determine what the base is - usercmds, root, sitename, api
		set p [file split $k]
		set base ""
		if {[lindex $p 4]=="server"} {
			set base api
		} elseif {[lindex $p 4]=="tclprocs"} {
			set base root
		} else {
			set base [lindex $p 4]
		}


		lappend result [dict create \
			file $k \
			lines $v \
			type $base \
			name [lindex $p end]
		]
	}

	return $result
}
#echo [_scriptSearch term]


