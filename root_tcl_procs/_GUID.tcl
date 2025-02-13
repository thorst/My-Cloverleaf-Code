if 0 {
	Param:
	Purpose:
		
	Links:
		http://core.tcl.tk/tcllib/doc/trunk/embedded/www/tcllib/files/modules/uuid/uuid.html
}
#

proc _guidNew {{includeDash true}} {
	package require uuid
	set guid [uuid::uuid generate]
	if {$includeDash} {
		return $guid
	} else {
		return [string map {- ""} $guid]
	}
}
#

proc _guidEmpty {} {
	return "00000000-0000-0000-0000-000000000000"
}