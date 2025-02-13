if 0 {
    _dbCount site db
        db - "r" or "e"
    
    Change Log:
        10/09/2017 - tmh
            -Initial
}
proc _dbCount {site db} {
	_siteSet $site
    return [exec ksh -c "hcidbdump -$db -C -U _dbCount[clock seconds]$db"]
}