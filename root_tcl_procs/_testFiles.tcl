proc _testFiles {site} {
	#Get the globals
	global env
	set HCIROOT $env(HCIROOT)
	
	#Determine path to tclIndex
	set path [file join $HCIROOT $site data_test]
	
	#Create it if it didnt already exist
	file mkdir $path
	
	#Get list of files
	set files [glob -nocomplain -directory $path -types f "*"]
	
	#Return data
	set scripts ""
	foreach name $files {

		lappend scripts [dict create \
							name [lindex [file split $name] end] \
							path $name
						]
	}
	return $scripts
}
