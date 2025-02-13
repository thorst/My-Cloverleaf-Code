if 0 {
	Param:
	Purpose:
		return a list of sites, according to the server.ini, for this server
		as a tcl list
}
#

proc _CscClientList {} {
	global env
	
	set cscLOC "$env(CSC_SERVER_HOME)/lws"
	
	# Get path like E:\cloverleaf\csc6.0\server\registered\default\sfm01
	
	set clientList ""
	set groups [glob -nocomplain -types d -directory "$cscLOC/registered/" *];#csc introduced groups


	foreach group $groups {
		set clients [glob -nocomplain -tails -types d -directory "$group" *];#csc introduced groups
		foreach client $clients {
			lappend clientList $client
		}
	}
	return $clientList
	
}
#