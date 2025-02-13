if 0 {
    This will look at a bunch of provider fields and ensure that the npi
    is in the mdm database. If not then set to historical if so leave it.

    Change Log:
    05/31/2017 - TMH
    -Added global list of providers so that you dont have
    to hit the db if you found that provider before
    06/06/2017 - TMH
    -Starting to add sqlite cache
}

proc _EPCProvNPIValidate {segList} {
    global HciConnName env
    global _NPI_List EpicProviders_sqlite3
    if {![info exists _NPI_List]} {set _NPI_List "";}

    # Ensure db path exists
    set dbPath $env(HCIROOT)/data_tables
    set dbFile EpicProviders.sqlite3
    set dbLocation "$dbPath/$dbFile"
    if {![file exists $dbPath]} {
        file mkdir $dbPath
    }

    # Determine if db Exists
    # If not create the file and structure
    if {![file exists $dbLocation]} {
        sqlite3 EpicProviders_sqlite3 $dbLocation
        EpicProviders_sqlite3 eval {PRAGMA journal_mode=WAL}

        # Create table(s)
        EpicProviders_sqlite3 eval {CREATE TABLE IF NOT EXISTS EpicProviders (
            npi INTEGER,
            UNIQUE(npi)
            );}

            EpicProviders_sqlite3 eval {CREATE TABLE IF NOT EXISTS NonEpicProviders (
                npi INTEGER,
                inserted TEXT,
                UNIQUE(npi)
                );}

                # Closing the db here will clean up the 2 WAL files
                EpicProviders_sqlite3 close
            }

            # Determine if handle exists, open if NOT
            # not so worried about closing since it will
            # use this handle while it exists
            if {![info exists providers_sqlite3]} {
            sqlite3 EpicProviders_sqlite3 $dbLocation
        }

        # For a bit have it create table
        EpicProviders_sqlite3 eval {CREATE TABLE IF NOT EXISTS NonEpicProviders (
            npi INTEGER,
            inserted TEXT,
            UNIQUE(npi)
            );}

            # These are offset because seglist starts with a squirly
            set fieldDelim [string index $segList 4]          ;# Field delimiter
            set comp_delim [string index $segList 5]           ;# Component delimiter
            set rep_delim [string index $segList 6]            ;# Repeat delimiter


            # Create a list of providers to query, and the list of ones that were found
            set ProvLookupList ""
            set foundProviders ""

            #-----------------------------------------------GATHER NPI--------------------
            #=========================================================
            # PV1
            #=========================================================
            set pv1Index [lsearch $segList "PV1|*"]
            if {$pv1Index>=0} {
            set fldList [split [lindex $segList $pv1Index] $fieldDelim]
            _lextend "fldList" 10

            set pv17 [split [lindex $fldList 7] $comp_delim]
            if {[string trim [lindex $pv17 0]]!=""} {
                lappend ProvLookupList [lindex $pv17 0]
            }

            set pv18 [split [lindex $fldList 8] $comp_delim]
            if {[string trim [lindex $pv18 0]]!=""} {
                lappend ProvLookupList [lindex $pv18 0]
            }

            set pv117 [split [lindex $fldList 17] $comp_delim]
            if {[string trim [lindex $pv117 0]]!=""} {
                lappend ProvLookupList [lindex $pv117 0]
            }
        }

        #=========================================================
        # TXA
        #=========================================================
        set txaIndex [lsearch $segList "TXA|*"]
        if {$txaIndex>=0} {
            set fldList [split [lindex $segList $txaIndex] $fieldDelim]

            set txa5 [split [lindex $fldList 5] $comp_delim]
            if {[string trim [lindex $txa5 0]]!=""} {
                lappend ProvLookupList [lindex $txa5 0]
            }
        }

        #=========================================================
        # OBR
        #=========================================================
        set obrIndex [lsearch $segList "OBR|*"]
        if {$obrIndex>=0} {
            set fldList [split [lindex $segList $obrIndex] $fieldDelim]
            _lextend "fldList" 32

            set obr16 [split [lindex $fldList 16] $comp_delim]
            if {[string trim [lindex $obr16 0]]!=""} {
                lappend ProvLookupList [lindex $obr16 0]
            }

            set obr32 [split [lindex $fldList 32] $comp_delim]
            if {[string trim [lindex $obr32 0]]!=""} {
                lappend ProvLookupList [lindex $obr32 0]
            }
        }

        #=========================================================
        # PD1
        #=========================================================
        set pd1Index [lsearch $segList "PD1|*"]
        if {$pd1Index>=0} {
            set fldList [split [lindex $segList $pd1Index] $fieldDelim]
            _lextend "fldList" 4

            set pd14 [split [lindex $fldList 4] $comp_delim]
            if {[string trim [lindex $pd14 0]]!=""} {
                lappend ProvLookupList [lindex $pd14 0]
            }
        }

        #-----------------------------------------------Consult cache before query--------------------
        # Create backup of lookup list
        set tempProvLookupList $ProvLookupList
        set ProvLookupList ""

        foreach p $tempProvLookupList {
            # if this isnt found in the global and its numeric
            # keep it on the lookup list
            #
            # if this is found and its numeric then add it to the
            # found list
            set isNumber [string is integer -strict $p]
            if {[lsearch $_NPI_List $p]==-1 && $isNumber} {
                lappend ProvLookupList $p
            } elseif {$isNumber} {
                lappend foundProviders $p
            }
        }
        #
        #echo ProvLookupList $ProvLookupList

        #-----------------------------------------------Consult sqlite cache before query--------------------
        # Create backup of lookup list
        set tempProvLookupList $ProvLookupList
        set ProvLookupList ""

        # By now we know they arent in memory, but are they in the local db
        foreach p $tempProvLookupList {

            set npi [EpicProviders_sqlite3 eval {SELECT npi FROM EpicProviders where npi = $p}]

            if {$npi==""} {
                # NPI still not found
                lappend ProvLookupList $p
            } else {
                lappend foundProviders $p
                lappend _NPI_List $p
            }
        }
        #echo ProvLookupList $ProvLookupList
        #

        #-----------------------------------------------Make query--------------------
        # Make sure there are providers to lookup before we make the query
        if {[llength $ProvLookupList]>0} {
            # Format provider list for query
            set joinProvLookupList "'[join $ProvLookupList "','"]'"

            # Make Query
            set query "SELECT mdm.Provider_xREF.mProviderCode_Code
            FROM mdm.Provider_xREF
            WHERE
            mdm.Provider_xREF.mProviderCode_Code in ($joinProvLookupList)
            And Provider_xREF.ss_active_Code='1'
            And Provider_xREF.src_sys_skey_Code='54'
            And Provider_xREF.mProviderCode_Code <> 'WSH9999999';"

            set server(server) ""
            set server(user) ""
            set server(password) ""

            set request(settings) "server"
            set request(query) $query
            set request(close_handle) false


            if {[odbc3_exec "request"]} {
                while {[odbc3_fetch "request"]} {
                    lappend foundProviders $request(col1)
                    lappend _NPI_List $request(col1)
                    EpicProviders_sqlite3 eval {INSERT OR IGNORE INTO EpicProviders (npi) VALUES ($request(col1))};
                }
            }
        }

        foreach p $ProvLookupList {
            if {[lsearch $foundProviders $p]==-1} {
                set inserted [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S.000"]
                EpicProviders_sqlite3 eval {INSERT OR IGNORE INTO NonEpicProviders (npi,inserted) VALUES ($p,$inserted)};
            }
        }
        #echo $_NPI_List

        #-----------------------------------------------Make changes--------------------

        #=========================================================
        # TXA
        #=========================================================
        if {$txaIndex>=0} {
            set fldList [split [lindex $segList $txaIndex] $fieldDelim]
            _lextend "fldList" 5

            set txa5 [split [lindex $fldList 5] $comp_delim]
            _lextend "txa5" 12
            if {[lsearch $foundProviders [lindex $txa5 0]]>=0} {
                lset txa5 12 "NPI"
            } else {
                lset txa5 0 "Historical"
                lset txa5 12 "PROVID"
            }
            lset fldList 5 [join $txa5 $comp_delim]

            # Commit changes
            lset segList $txaIndex [join $fldList $fieldDelim]
        }

        #=========================================================
        # PV1
        #=========================================================
        if {$pv1Index>=0} {
            set fldList [split [lindex $segList $pv1Index] $fieldDelim]
            _lextend "fldList" 17

            set pv17 [split [lindex $fldList 7] $comp_delim]
            _lextend "pv17" 12
            if {[lsearch $foundProviders [lindex $pv17 0]]>=0} {
                lset pv17 12 "NPI"
            } else {
                lset pv17 0 "Historical"
                lset pv17 12 "PROVID"
            }
            lset fldList 7 [join $pv17 $comp_delim]

            # PV1 8
            set pv18 [split [lindex $fldList 8] $comp_delim]
            _lextend "pv18" 12
            if {[lsearch $foundProviders [lindex $pv18 0]]>=0} {
                lset pv18 12 "NPI"
            } else {
                lset pv18 0 "Historical"
                lset pv18 12 "PROVID"
            }
            lset fldList 8 [join $pv18 $comp_delim]

            # PV1 17
            set pv117 [split [lindex $fldList 17] $comp_delim]
            _lextend "pv117" 12
            if {[lsearch $foundProviders [lindex $pv117 0]]>=0} {
                lset pv117 12 "NPI"
            } else {
                lset pv117 0 "Historical"
                lset pv117 12 "PROVID"
            }
            lset fldList 17 [join $pv117 $comp_delim]

            # Commit changes
            lset segList $pv1Index [join $fldList $fieldDelim]
        }

        #=========================================================
        # OBR
        #=========================================================
        if {$obrIndex>=0} {
            set fldList [split [lindex $segList $obrIndex] $fieldDelim]
            _lextend "fldList" 32

            set obr16 [split [lindex $fldList 16] $comp_delim]
            _lextend "obr16" 12
            if {[lsearch $foundProviders [lindex $obr16 0]]>=0} {
                lset obr16 12 "NPI"
            } else {
                lset obr16 0 "Historical"
                lset obr16 12 "PROVID"
            }
            lset fldList 16 [join $obr16 $comp_delim]

            # OBR 32
            set obr32 [split [lindex $fldList 32] $comp_delim]
            _lextend "obr32" 12
            if {[lsearch $foundProviders [lindex $obr32 0]]>=0} {
                lset obr32 12 "NPI"
            } else {
                lset obr32 0 "Historical"
                lset obr32 12 "PROVID"
            }
            lset fldList 32 [join $obr32 $comp_delim]

            # Commit changes
            lset segList $obrIndex [join $fldList $fieldDelim]
        }

        #=========================================================
        # PD1
        #=========================================================
        if {$pd1Index>=0} {
            set fldList [split [lindex $segList $pd1Index] $fieldDelim]
            _lextend "fldList" 4

            set pd14 [split [lindex $fldList 4] $comp_delim]
            _lextend "pd14" 12
            if {[lsearch $foundProviders [lindex $pd14 0]]>=0} {
                lset pd14 12 "NPI"
            } else {
                lset pd14 0 "Historical"
                lset pd14 12 "PROVID"
            }
            lset fldList 4 [join $pd14 $comp_delim]

            # Commit changes
            lset segList $pd1Index [join $fldList $fieldDelim]
        }

        EpicProviders_sqlite3 close
        return $segList
    }
