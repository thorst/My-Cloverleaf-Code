if 0 {
	Purpose:
	Ftp a file to a server. Default information to momentums credentials.

	Links:
	http://core.tcl.tk/tcllib/doc/trunk/embedded/www/tcllib/files/modules/ftp/ftp.html

	Param List:
	settings is a dictionary with the below entries

	Settings Dict:
	FIELD       TYPE            DEFAULT                 DESCRIPTION
	Required:
	put         list of dict    -               		A list of dictionaries
	content	string  		-						The name of file, or data to put, or channel for reading (channel closed afterwords), if no path, uses pwd
	type	string  		local					Possible choices: "local","channel","data".
	name 	string  		- 						The name of the remote file (optional if type is local, will just use same name)
	delete 	boolean  		false 					If it was local, delete the file

	Not Required:
	directory   string		                    	Directory on the server
	server		string  			Server to connect to
	user		string  				User to connect as
	password	string  						Password to use to connect
	prefix		string  		-						Prefix filenames with
	suffix		string  		-						Append to filename
	type		string   		binary					Connection method

	Examples:

	For our sample we use env and also epoch with random numbers to ensure uniqueness
	global env
	set cSec [clock seconds]                                                    ;#Current second (epoch time)
	set rand [expr { rand() }]

	Now I want to send a string instead of having to write data out. I prefix and suffix
	with some random data. I ahve echo turned on, so if anything fails it just goes into
	the log.
	_FTP [dict create \
		suffix .$cSec$rand.txt \
		prefix . \
		echo true \
		put [list \
			[dict create \
			content [file join $env(HCIROOT) tclprocs _fileGet.tcl] \
			type data \
			name "Test"
		]
		]
		]

		This sample is a little more common. We have a physician file we want to send. Im
		just going to use the same name locally for the remote file (with suffix and prefix)

		_FTP [dict create \
			put [list \
				[dict create content [file join $env(HCIROOT) tclprocs _fileGet.tcl]]
			]
			]

			Now I want to connect to a different server other than momentum.

			_FTP [dict create \
				server www..org \
				user  \
				password  \
				directory "" \
				put [list \
					[dict create \
					content "Hello from " \
					type data \
					name "Test"
				]
				]
				]
			}
			#

			package require ftp

			proc _FTP {settings} {

				#Verify required settings are there
				if {![dict exists $settings put]} {
					echo "FTP Error:: Need to define at least 'put' in settings."
					return false
				}

				set settings [dict merge [dict create \
					directory "" \
					server "..org" \
					user "/" \
					password "" \
					prefix "" \
					suffix "" \
					type "" \
					echo false \
					] $settings]

				#Open session
				set session [::ftp::Open [dict get $settings server] [dict get $settings user] [dict get $settings password]]
				if {$session==-1} {
					set err "FTP Error:: Failed connecting to server"
					if {[dict get $settings server]} {echo $err;}
					return $err
				}

				#Change the type
				if {[dict get $settings type]!=""} {
					set type [::ftp::Type $session [dict get $settings type]]
					if {$type!=[dict get $settings type]} {
						set err "FTP Error:: Failed changing type"
						if {[dict get $settings server]} {echo $err;}
						return $err
					}
				}

				#Change the directory
				if {[dict get $settings directory]!=""} {
					set cdDir [::ftp::Cd $session [dict get $settings directory]]
					if {$cdDir==0} {
						set err "FTP Error:: Failed changing directories"
						if {[dict get $settings server]} {echo $err;}
						return $err
					}
				}

				foreach put [dict get $settings put] {

					#Default type
					if {![dict exists $put type]} { dict set put type local }

					#Make sure content has something in it
					if {![dict exists $put content]} { continue; }

					###########################
					#If type is local file
					if {[dict get $put type]=="local"} {

						#if the file doesnt exist move on
						if {![file exists [dict get $put content]]} {
							continue
						}

						#default the delete and name fields
						if {![dict exists $put delete]} { dict set put delete false }
						if {![dict exists $put name]} { dict set put name [lindex [file split [dict get $put content]] end] }

						#Add prefix/suffix
						if {[dict get $settings prefix]!=""} {
							dict set put name "[dict get $settings prefix][dict get $put name]"
						}
						if {[dict get $settings suffix]!=""} {
							dict set put name "[dict get $put name][dict get $settings suffix]"
						}

						set pFile [::ftp::Put $session [dict get $put content] [dict get $put name]]

						#if they want to delete the file
						if {$pFile==1 && [dict get $put delete]} {
							file delete -force [dict get $put content]
						}

						continue
					}

					###########################
					#If type is channel or data

					#Ensure name was passed
					if {![dict exists $put name]} { continue; }

					#Add prefix/suffix
					if {[dict get $settings prefix]!=""} {
						dict set put name "[dict get $settings prefix][dict get $put name]"
					}
					if {[dict get $settings suffix]!=""} {
						dict set put name "[dict get $put name][dict get $settings suffix]"
					}

					set pFile [::ftp::Put $session -[dict get $put type] [dict get $put content] [dict get $put name]]
				}


				#Close session
				::ftp::Close $session
			}
			#