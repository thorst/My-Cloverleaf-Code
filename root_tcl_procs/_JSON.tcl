if 0 {
	##Documentation
	http://core.tcl.tk/tcllib/doc/trunk/embedded/www/tcllib/files/modules/yaml/huddle.html

	##Create
	set Json [jObject \
		User  \
		Level 100 \
		Groups [jArray \
			[jObject \
				Id 112 \
				Title "-"
			] \
				[jObject \
					Id 113 \
					Title "-"
				]
				]
				]
				set raw [jRender $Json]
				echo $raw
				echo [jRenderF $Json]

				#Commonly youll need to append in loop
				set siteList [jArray 1];#initialize with one fake element
				foreach site $sites {
					set siteList [jAppend $siteList [lindex [split $site "\\"] end]]
				}
				set siteList [jRemove $siteList 0]; #remove fake element


				##Parse
				set parsed [jParse $raw]					;#Parse json
				set Groups [dict get $parsed Groups]		;#Get Groups obj
				set Group1 [lindex $Groups 0]				;#Get first photo1
				set id [dict get $Group1 Id]				;#Get Id
				set User [dict get $parsed User]			;#Get photo array
				echo $id
				echo $User

				##Changes
				2016-02-02 thorst02
				-Upgraded huddle from 1.5 to 2.0
				-Added jTrue, jFalse, and jBool {arg}, jList, jNum, jString
			}

			# These only get added once the file has been sourced
			# So until you call one of these proc you will not have
			# huddle and json
			package require json
			package req huddle

			proc jArray {args} {
				return [huddle list {*}$args];
			}
			proc jObject {args} {
				return [huddle create {*}$args];
			}
			proc jAppend {obj args} {
				return [huddle append obj {*}$args];
			}
			proc jRemove {obj args} {
				return [huddle remove $obj {*}$args];
			}
			proc jRender {args} {
				return [huddle jsondump {*}$args "" ""];
			}
			proc jRenderF {args} {
				return [huddle jsondump {*}$args];
			}
			proc jParse {arg} {
				return [json::json2dict $arg];
			}
			proc jCompile {spec data} {
				return [huddle compile $spec $data];
			}
			proc jTrue {} {
				return [huddle true]
			}
			proc jFalse {} {
				return [huddle false]
			}
			proc jBool {arg} {
				return [huddle boolean $arg]
			}
			proc jNum {arg} {
				return [huddle number $arg]
			}
			proc jList {args} {
				return [huddle list {*}$args]
			}
			proc jString {arg} {
				return [huddle string $arg]
			}