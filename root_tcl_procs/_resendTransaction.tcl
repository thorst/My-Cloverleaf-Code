proc _resendTransaction {site process thread direction file} {
	#get context
	_siteSet $site


	#hcicmd -p sandbox -c 'conn_18 resend ib_pre_tps data 5120 ""//qdx5.7/integrator/dbexport/e.test_physician. 2013.02.04-11.19...23.268.txt"" nl'

	set output [exec ksh -c "hcicmd -p $process -c '$thread resend $direction data 5120 \"$file\" nl'"]
	#set output [exec hcicmd -p $process -c '$thread resend $direction data 5120 \"$file\" nl']

	set successful true
	if {[string match -nocase "*Placed * msgs from file $file into the $direction data queue*" $output]==0} {
		set successful false
	}
	return [dict create \
		successful $successful \
		output $output
	]
}
#_dbList physician e