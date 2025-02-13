if 0 {
    This will look at a bunch of provider fields and convert the entity to npi
    from the mdm database. If not then set to historical.

    Change Log:
    05/31/2017 - TMH
    -Added global list of providers so that you dont have
    to hit the db if you found that provider before
}
#
if 0 {
    This will take a field and pull out the provider number and then
    add it to the list of ones to lookup
}
proc _ProvEntityToNPI_getNum {fld} {
    upvar ProvLookupList ProvLookupList
    upvar comp_delim comp_delim

    set fl [split $fld $comp_delim]
    if {[string trim [lindex $fl 0]]!=""} {
        lappend ProvLookupList [string trimleft [lindex $fl 0] "0"]
    }
}
#
if 0 {
    This will take a field and either put in the npi or historical
}
proc _ProvEntityToNPI_replace {fldIdx} {
    upvar fldList fldList
    upvar comp_delim comp_delim
    global _NPI_ListPair

    set fl [split [lindex $fldList $fldIdx] $comp_delim]
    _lextend "fl" 12
    set search [lsearch -inline $_NPI_ListPair "[string trimleft [lindex $fl 0] 0]|*"]
    if {$search!=""} {
        lset fl 0 [lindex [split $search "|"] 1]
        lset fl 12 "NPI"
    } else {
        lset fl 0 "Historical"
        lset fl 12 "PROVID"
    }
    lset fldList $fldIdx [join $fl $comp_delim]
}
#
if 0 {
    This is the main proc that parses the message and respective fields
}
proc _ProvEntityToNPI {segList} {

    global HciConnName
    global _NPI_ListPair
    if {![info exists _NPI_ListPair]} {set _NPI_ListPair "";}

    # These are offset because seglist starts with a squirly
    set fieldDelim [string index $segList 4]          ;# Field delimiter
    set comp_delim [string index $segList 5]           ;# Component delimiter
    set rep_delim [string index $segList 6]            ;# Repeat delimiter

    # Create a list of providers to query
    set ProvLookupList ""

    #-----------------------------------------------GATHER NPI--------------------
    #=========================================================
    # PV1
    #=========================================================
    set pv1Index [lsearch $segList "PV1|*"]
    if {$pv1Index>=0} {
        set fldList [split [lindex $segList $pv1Index] $fieldDelim]
        _lextend "fldList" 10

        _ProvEntityToNPI_getNum [lindex $fldList 7]
        _ProvEntityToNPI_getNum [lindex $fldList 8]
        _ProvEntityToNPI_getNum [lindex $fldList 17]
    }

    #=========================================================
    # TXA
    #=========================================================
    set txaIndex [lsearch $segList "TXA|*"]
    if {$txaIndex>=0} {
        set fldList [split [lindex $segList $txaIndex] $fieldDelim]

        _ProvEntityToNPI_getNum [lindex $fldList 5]
    }

    #=========================================================
    # OBR
    #=========================================================
    set obrIndex [lsearch $segList "OBR|*"]
    if {$obrIndex>=0} {
        set fldList [split [lindex $segList $obrIndex] $fieldDelim]
        _lextend "fldList" 32

        _ProvEntityToNPI_getNum [lindex $fldList 16]
        _ProvEntityToNPI_getNum [lindex $fldList 32]

    }

    #=========================================================
    # PD1
    #=========================================================
    set pd1Index [lsearch $segList "PD1|*"]
    if {$pd1Index>=0} {
        set fldList [split [lindex $segList $pd1Index] $fieldDelim]
        _lextend "fldList" 4

        _ProvEntityToNPI_getNum [lindex $fldList 4]
    }

    #-----------------------------------------------Consult cache before query--------------------
    # Create backup of lookup list
    set tempProvLookupList $ProvLookupList
    set ProvLookupList ""

    foreach p $tempProvLookupList {
        # if this isnt found in the global and its numeric
        # keep it on the lookup list
        set isNumber [string is integer -strict $p]
        if {[lsearch -inline $_NPI_ListPair "$p|*"]=="" && $isNumber} {
            lappend ProvLookupList $p
        }
    }
    echo ProvLookupList$ProvLookupList
    #

    #-----------------------------------------------Make query--------------------
    # Make sure there are providers to lookup before we make the query
    if {[llength $ProvLookupList]>0} {
        # Format provider list for query
        set ProvLookupList "'[join $ProvLookupList "','"]'"

        # Make Query
        set query "SELECT mdm.Provider_xREF.ss_key3, mdm.Provider_xREF.mProviderCode_Code
        FROM mdm.Provider_xREF
        WHERE mdm.Provider_xREF.ss_key3 in ($ProvLookupList)
        And Provider_xREF.ss_active_Code=1
        And Provider_xREF.src_sys_skey_Code=2
        And Provider_xREF.mProviderCode_Code <> '9999999';"

        set server(server) ""
        set server(user) ""
        set server(password) ""

        set request(settings) "server"
        set request(query) $query
        set request(close_handle) false


        if {[odbc3_exec "request"]} {
            while {[odbc3_fetch "request"]} {
                lappend _NPI_ListPair $request(col1)|$request(col2)
            }
        }
    }
    echo _NPI_ListPair$_NPI_ListPair
    #-----------------------------------------------Make changes--------------------

    #=========================================================
    # TXA
    #=========================================================
    if {$txaIndex>=0} {
        set fldList [split [lindex $segList $txaIndex] $fieldDelim]
        _lextend "fldList" 5

        _ProvEntityToNPI_replace 5

        # Commit changes
        lset segList $txaIndex [join $fldList $fieldDelim]
    }

    #=========================================================
    # PV1
    #=========================================================
    if {$pv1Index>=0} {
        set fldList [split [lindex $segList $pv1Index] $fieldDelim]
        _lextend "fldList" 17

        _ProvEntityToNPI_replace 7
        _ProvEntityToNPI_replace 8
        _ProvEntityToNPI_replace 17

        # Commit changes
        lset segList $pv1Index [join $fldList $fieldDelim]
    }

    #=========================================================
    # OBR
    #=========================================================
    if {$obrIndex>=0} {
        set fldList [split [lindex $segList $obrIndex] $fieldDelim]
        _lextend "fldList" 32

        _ProvEntityToNPI_replace 16
        _ProvEntityToNPI_replace 32

        # Commit changes
        lset segList $obrIndex [join $fldList $fieldDelim]
    }

    #=========================================================
    # PD1
    #=========================================================
    if {$pd1Index>=0} {
        set fldList [split [lindex $segList $pd1Index] $fieldDelim]
        _lextend "fldList" 4

        _ProvEntityToNPI_replace 4

        # Commit changes
        lset segList $pd1Index [join $fldList $fieldDelim]
    }

    return $segList
}