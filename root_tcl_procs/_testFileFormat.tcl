if 0 {
	2015-04-01 Todd Horst
	-Initial version, port of c# code
	2016-11-29 Todd Horst
	-Added point to a dir and apply a filter
	2017-11-07 Steve
	-A change to an OBX to NTE script for lab results caused an issue where there is no carriage return before the MSH segment.
	We now look for MSH| when separating messages instead of carriage return + MSH
}
#

proc _testFileFormat {filedir {filter *}} {

	if {[file isdirectory $filedir]} {
		set files [glob -type f "$filedir/$filter"]

	} else {
		set files [list $filedir]
	}

	foreach {file} $files {

		# Read in all the data
		set fl [open $file]
		set data [read $fl]
		if {[catch {close $fl} err]} {
			puts "ls command failed: $err"
		}

		# Delete the old file
		file delete -force $file

		# Replace newlines with carrage returns
		set data [string map {\n \r} $data]

		# Continuously remove double returns
		while {[string first \r\r $data]>=0} {
			set data [string map {\r\r \r} $data]
		}

		# Replace all instances of carriage return + MSH| with just MSH|
		set data [string map {\rMSH| MSH|} $data]

		# Seperate the messages with a carriage return and a newline
		set data [string map {MSH| \r\nMSH|} $data]

		# End the file with a crlf
		set data [string trim $data]\r\n

		# Write file
		set fl [open $file w]
		puts -nonewline $fl $data
		if {[catch {close $fl} err]} {
			puts "ls command failed: $err"
		}
	}
}
