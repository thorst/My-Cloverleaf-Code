if 0 {
	#<
		Author: Todd Horst
		
		This function will return the proc as its written
		in the file. This may be helpful for learning how
		someone coded something, or if you want to eval
		a script.
	
		Example:
		
		Change Log:
		03/09/2015 - 
		 * Created (stolen from https://www.tcl.tk/man/tcl8.4/TclCmd/info.htm)
	#>
}
#
proc _procGetAsString {procName} {
    set result [list proc $procName]
    set formals {}
    foreach var [info args $procName] {
        if {[info default $procName $var def]} {
            lappend formals [list $var $def]
        } else {
            # Still need the list-quoting because variable
            # names may properly contain spaces.
            lappend formals [list $var]
        }
    }
    return [lappend result $formals [info body $procName]]
}
#