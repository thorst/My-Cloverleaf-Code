if 0 {
    _dbSave
        Save out a transaction(s) from the error or recover database
    
    Change Log:
        09/06/2017 - tmh
            -Allow deleting transaction so its one step
}
proc _dbSave {site db messageIds file {delete false}} {
	global env
	set HCIROOT $env(HCIROOT)
	set file [string map "\$HCIROOT $HCIROOT" $file]
	#set file [join [split $file \$HCIROOT] $HCIROOT]
	#echo [split $file \$HCIROOT]
	#_dbFullDetails {site db messageId}
	set fl [open $file w]

	foreach id $messageIds {
		set results [_dbFullDetails $site $db $id $delete]
		set message [dict get $results message]
		#.Substring(24).Trim().Trim('\'').Trim().Replace("\\x0a", "\n").Replace("\\x0d", "\r").Replace("\\x0b", "") + "\r\n";
		puts -nonewline $fl $message\n
	}
	
	close $fl
}
#_dbSave physician e [1] 