if 0 {
	Param:
	Purpose:
		given a file, retrieve its contents
				
	Change Log:
	    2018-12-10 TMH
	        -Proper fix for windows with HCIROOT replacement using list instead of fake list
}
#

proc _fileGet {file} {
	global env
	set HCIROOT $env(HCIROOT)
	set file [string map [list \$HCIROOT $HCIROOT] $file]
	set fl [open $file]
	set contents [read $fl]
	if {[catch {close $fl} err]} {
		puts "ls command failed: $err"
	}
	return $contents;
}
#
