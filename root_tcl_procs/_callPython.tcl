##################################################################
##		Exectue Python scripts from within Tcl		##
##		    Created by: Jonathan  		##
##			Date Created: 12/30/2019		##
##			Date Changed: --/--/----		##
##	 	   Change Completed: -				##
##################################################################

proc _call_python_no_uargs {scriptPath} {
	set output [exec python $scriptPath]
	puts $output
}

proc _call_python_with_uargs { args } {
	set uargs {} ; keylget args ARGS uargs
	set output [exec python $uargs]
	puts $output
}
