if 0 {
	Param:
	Purpose:
		Given contents write a file
}
#

proc _filePut {file contents} {
	catch {
		global env; set HCIROOT $env(HCIROOT)
		set file [string map [list \$HCIROOT $HCIROOT] $file]
		set contents [_baseDencode $contents]
		set fl [open $file w]
		puts -nonewline $fl $contents
		if {[catch {close $fl} err]} {
			puts "ls command failed: $err"
		}
	} writeerr
	return $writeerr;
}
#


