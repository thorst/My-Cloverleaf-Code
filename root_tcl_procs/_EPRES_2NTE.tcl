if 0 {
    HISTORY:
    05/16/2017 - TMH
        - Fixed unintialized var
        - Added history section in notes
}
proc _EPRES_2NTE {segList} {

	set field_delim [string index $segList 4]          ;# Field delimiter
    set comp_delim [string index $segList 5]           ;# Component delimiter
    set rep_delim [string index $segList 6]

	#=========================================================
    # OBR
    #=========================================================
    set segIndex [lsearch $segList "OBR|*"]
    set resType ""
    if {$segIndex>=0} {
        set fldList [split [lindex $segList $segIndex] $field_delim]
        _lextend "fldList" 10
		
		set OBR4 [lindex $fldList 4]
		set resType [lindex [split [lindex $fldList 24] ","] 0]
			
	}
	 
	#=========================================================
    # OBX
    #=========================================================
	set header false
    foreach segIndex [lsearch -all $segList "OBX|*"] {
    set fldList [split [lindex $segList $segIndex] $field_delim]
    _lextend "fldList" 10
			
			set firstobx [lindex $segList $segIndex]
			
			set obx1 [lindex $fldList 1]
			set obx5 [lindex $fldList 5]
			set obx3 [lindex [split [lindex $fldList 3] $comp_delim] 8]
			set obx3_1 [lindex [split [lindex $fldList 3] $comp_delim] 1]
			set obx23LabName [lindex [split [lindex $fldList 23] $comp_delim] 0]
			#echo "obxLab" $obx23LabName

		if {$resType == "Microbiology"} {
	
			#create list of new NTE segs from OBX segs
			lappend nteList [join [list "NTE" "$obx1" "" "$obx5|"] $field_delim]
		
		} elseif {$resType == "Path"} {
					if {$header == false} {
						#echo $header
						set header $obx3_1	
						lappend nteList [join [list "NTE" "$obx1" "" "|"] $field_delim]
						lappend nteList [join [list "NTE" "$obx1" "" "$obx3_1|"] $field_delim]
						lappend nteList [join [list "NTE" "$obx1" "" "  $obx5|"] $field_delim]
						
					} elseif {$header == $obx3_1} {
						#echo $header
						lappend nteList [join [list "NTE" "$obx1" "" "  $obx5|"] $field_delim]
						#echo "Header Exist"
						
					} elseif {$header != $obx3_1} {

						set header $obx3_1
						lappend nteList [join [list "NTE" "$obx1" "" "|"] $field_delim]
						lappend nteList [join [list "NTE" "$obx1" "" "$header|"] $field_delim]
						lappend nteList [join [list "NTE" "$obx1" "" "  $obx5|"] $field_delim]

					}
		
		}
		
		# Commit changes
		lset segList $segIndex [join $fldList $field_delim]
	}
	#echo $nteList
	#=========================================================
    # NTE Insert
    #=========================================================
			
	if {$resType == "Path" || $resType == "Microbiology"} {
		set segIndex [lsearch $segList "OBX|*"]
		if {$segIndex>=0} {
		
			set nteList [lreverse $nteList]
			
			foreach seg $nteList {
				set segList [linsert $segList $segIndex $seg]
			}
			
		}
		
		_lremoveVals "segList" [list "OBX|*"]
		
		# Add the custom segment for path result data retention
			lappend segList "ZPL|$obx23LabName"
	}
	
	
	#=========================================================
    # TQ1
    #=========================================================
    set pathology [lsearch $resType "Path*"]
    set micro [lsearch $resType "Microb*"]

    if {$pathology>=0 || $micro>=0 } {
        set segIndex [lsearch $segList "TQ1|*"]
        if {$segIndex>=0} {
            _lremove segList $segIndex
            set fldList [split $firstobx $field_delim]
            lset fldList 5 "See Note"
            if {[lindex $fldList 3] == ""} {
                lset fldList 3 $OBR4
            }
            set segList [linsert $segList $segIndex [join $fldList $field_delim]]
        }
    }
	#renumkber the new NTE segments
	#_segRenumber "segList" [list obx nte]
	
	return $segList
}