if 0 {
	OWNER:

	VERSION::
	1.0
	ABOUT::
	This provides a globally available alternative to cloverleaf translation tables.
	This is the query proc that can be called to acccess the global dictionary

	CHANGE LOG::
	2018-01-17 - TMH
	Fixed closing handle, moved before returns

	TODO::

	USE CASE EXAMPLE::
	usage:
	set the result var [_readDict *dictionaryName *dictionaryKey]

	example:
	set file ""
	set key "CALLAHD 2"
	echo [_readDict $file $key]
}
#
proc _readDict {file key} {
	#set enviroment
	global env
	set HCIROOT $env(HCIROOT)

	#indentify and locate the table
	set arc "$HCIROOT/cltables/$file.txt"
	set file [split [exec find $arc -name "*.txt*" -type f]]

	#open and read the file
	set chan [open $file]
	set tablet [read $chan]
	close $chan

	#set the dict
	set tablet [lindex $tablet 0]

	#get the value if found
	if {[dict exist $tablet $key]} {
		return [dict get $tablet $key]
	}

	#if no value, handle exceptions by returning the key
	return $key
}
