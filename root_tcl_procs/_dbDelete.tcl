if 0 {
	Delete message(s) in a database
	
	site: 		"test_physician"
	db: 		"e" | "r"
	messageIds: [1,2,3]
}
proc _dbDelete {site db messageIds} {
	
	#get context
	_siteSet $site
	
	foreach id $messageIds {
		set output [exec hcidbdump -$db -D -F -m $id:$id]
	}
	
	return 1
}
#_dbDelete physician e 0