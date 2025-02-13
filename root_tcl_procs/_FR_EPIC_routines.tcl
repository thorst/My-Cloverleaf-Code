if 0 {
    Script:
    _FR_EPIC_OrderField fieldName fieldlabel ?component? ?repetition?
    fieldName is the entire mrn or provider field
    fieldlabel is the identifier type to move first
    component is optional and defaults to ^
    repetition is optional and defaults to ~

    Description:
    Reorder a field putting the specified type first
    mrn data like this
    provider data like this

    Example:
    Call for mrn field like this for PID-3 or MRG-1
    set mrn [_FR_EPIC_OrderField [lindex $fldList 3] ""]
    set mrn [_FR_EPIC_OrderField [lindex $fldList 3] ""]

    Call for provider field like this for PV1-7, etc
    set prv [_FR_EPIC_OrderField [lindex $fldList 7] ""]
    set prv [_FR_EPIC_OrderField [lindex $fldList 7] ""]

    History:
    03/07/2018 -  -Initial version
}
#
proc _FR_EPIC_OrderField {fld fldlabel {comp_delim "^"} {rep_delim "~"}} {



    # split the field and search for the specified label position in the list
    set fieldList [split $fld $rep_delim]
    set fldindex [lsearch $fieldList "*$comp_delim$fldlabel"]

    # if label exists do the reordering, else return original field
    if {$fldindex > 0} {
        # move specified label to the front of the list
        set fieldList [linsert $fieldList 0 [lindex $fieldList $fldindex]]
        # remove specified label from its original list position
        _lremove fieldList [expr {$fldindex + 1}]
    }

    # join field list and return it
    set fld [join $fieldList $rep_delim]
    return $fld
}
#


if 0 {
    Script:
    _FR_EPIC_kill listName ?field? ?component? ?repetition?
    listName is the entire list of segments
    field is optional and defaults to |
    component is optional and defaults to ^
    repetition is optional and defaults to ~

    Description:
    check to see if message should be killed
    return true or false

    Example:
    Call this routine like this
    set killflag [_FR_EPIC_kill $segList]

    History:
    03/07/2018 -  -Initial version
    03/29/2019 -  - Added MSH and EVN section to KIll messages with PEF_ADT and A03 in the transaction.
}
#
proc _FR_EPIC_kill {segList {field_delim "|"} {comp_delim "^"} {rep_delim "~"}} {

    #========================================================
    # MSH
    #========================================================
    set segIndex [lsearch $segList "MSH|*"]
    if {$segIndex>=0} {
        set fldList [split [lindex $segList $segIndex] $field_delim]

        # get the message type
        set msh8 [string toupper [lindex $fldList 8]]
        set msgType [lindex [split $msh8 $comp_delim] 1]
    }

    #========================================================
    # EVN
    #========================================================
    set segIndex [lsearch $segList "EVN|*"]
    if {$segIndex>=0} {
        set fldList [split [lindex $segList $segIndex] $field_delim]

        #Get the EVN.4 value and kill if it is an A03 and EVN.4 is .  These are the  Discharges and are not used.  THe A03 has no PV1.
        set trigger [lindex $fldList 4]
        if {[string equal $msgType "A03"] && [string equal $trigger ""]} {
            return true
        }
    }

    #=========================================================
    # PID
    #=========================================================
    set segIndex [lsearch $segList "PID|*"]
    if {$segIndex>=0} {
        set fldList [split [lindex $segList $segIndex] $field_delim]

        # get the PID-3 mrn, split, and search for MRN label
        # you must split it for lsearch to work, else doesn't work when RN is first and EID second
        set mrn [lindex $fldList 3]
        set mrnList [split $mrn $rep_delim]
        set index [lsearch $mrnList "*$comp_delim"]

        # Kill if no RN - calling program can kill message
        if {$index == -1} {
            return true
        }

        # kill of Last name ZZTEST
        set lname [lindex [split [lindex $fldList 5] $comp_delim] 0]
        if {$lname == "ZZTEST"} {
            return true
        }
    }

    return false
}
#


if 0 {
    Script:
    _FR_EPIC_formatter listName ?field? ?component? ?repetition?
    listName is the entire list of segments
    field is optional and defaults to |
    component is optional and defaults to ^
    repetition is optional and defaults to ~

    Description:
    Formats all provider fields and other fields in PV1, MSH, PID

    Example:
    set segList [_FR_EPIC_formatter $segList]

    History:
    03/07/2018 -  -Initial version
}
#
proc _FR_EPIC_formatter {segList {field_delim "|"} {comp_delim "^"} {rep_delim "~"}} {

    #=========================================================
    # move NPI to 1st repetition in each of these fields
    #=========================================================
    set docfields [list [list PD1 4] [list PV1 7 8 9 17] [list ORC 12] [list OBR 16 32] [list TXA 5 9 10 22]]
    foreach x $docfields {
        set newList [split $x \x20]
        set segname [lindex $newList 0]
        set docfldList [lrange $newList 1 end]

        # loop through all the indexes for each segment
        set indexes [lsearch -all $segList "$segname|*"]
        foreach segIndex $indexes {
            set fldList [_lextend [split [lindex $segList $segIndex] $field_delim] 40]
            #do we need to lextend all to 40 like original?

            # loop through all the fields for this segment
            foreach i $docfldList {
                # call proc that moves NPI to first rep
                set fld [_FR_EPIC_OrderField [lindex $fldList $i] "NPI"]
                lset fldList $i $fld
            }
            lset segList $segIndex [join $fldList $field_delim]
        }
    }

    #=========================================================
    # PV1 formatter
    #=========================================================
    set fac ""
    set csn ""
    set revLoc ""
    set dept ""
    set facMnemonic ""

    set segIndex [lsearch $segList "PV1|*"]
    if {$segIndex>=0} {
        set fldList [split [lindex $segList $segIndex] $field_delim]
        _lextend "fldList" 20

        # Get PV1-3 patient location
        # Facility = last 4 characters of dep 4001 but just use last 3
        set fld [string toupper [lindex $fldList 3]]
        set subfldList [_lextend [split $fld $comp_delim] 4]
        set dept [lindex $subfldList 0]
        set bed [lindex $subfldList 2]
        set revLoc [lindex $subfldList 3]
        set bedLtr [lindex [split $bed "-"] 1]
        set fac [string trim [string range $revLoc end-2 end]]
        set facMnemonic [string trim [string range $revLoc end-3 end]]      ;#Grab the last 4 characters of the Rev Loc to look for AHSC and RHSC.
        # Replace bed with letter
        set subfldList [lreplace $subfldList 2 2 $bedLtr]
        # Join patient location
        set fld [join $subfldList $comp_delim]
        lset fldList 3 $fld

        # Get PV1-6 previous patient location
        set fld [string toupper [lindex $fldList 6]]
        set subfldList [_lextend [split $fld $comp_delim] 4]
        set bed [lindex $subfldList 2]
        set bedLtr [lindex [split $bed "-"] 1]
        # Replace bed with letter
        set subfldList [lreplace $subfldList 2 2 $bedLtr]
        # Join previous patient location
        set fld [join $subfldList $comp_delim]
        lset fldList 6 $fld



        # uppercase the Pt Class, Service, and Financial Class
        lset fldList 2 [string toupper [lindex $fldList 2]]
        lset fldList 10 [string toupper [lindex $fldList 10]]
        lset fldList 20 [string toupper [lindex $fldList 20]]

        # EPIC sends CSN in PV1-19
        set csn [lindex $fldList 19]

        # Commit changes
        lset segList $segIndex [join $fldList $field_delim]
    }

    #=========================================================
    # MSH formatter
    #=========================================================
    set segIndex [lsearch $segList "MSH|*"]
    if {$segIndex>=0} {
        set fldList [split [lindex $segList $segIndex] $field_delim]
        _lextend "fldList" 10

        # get the message type/event
        set msh8 [string toupper [lindex $fldList 8]]
        set msgEvent [lindex [split $msh8 $comp_delim] 1]

        # exception facilities fixes
        set ghList [list "" "" ""]
        set ehList [list ""]
        if {[lsearch $ghList $revLoc]>=0} {set fac ""}
        if {[lsearch $ehList $revLoc]>=0} {set fac ""}

        #If last 4 characters of Rev Location are AHSC or RHSC, change to AH or HF.
        if {[string equal $facMnemonic ""]} {set fac "H"}
        if {[string equal $facMnemonic ""]} {set fac ""}

        # make these transaction types YH
        if {$msgEvent == "A28" || $msgEvent == "A31" || $msgEvent == "A40" || $msgEvent == "V04"} {
            set fac ""
        }

        # MSO comes at the start not the end of the location
        if {[string range $dept 0 2] == "MSO"} {set fac "MSO"}


        if {[string equal $facMnemonic ""]} {set fac ""}

        # Fix up a few facilities
        set fac [string map {} $fac]

        # only keep these facilities for all but Lexmark, blank out other invalid facilities
        set keepFacList [list ]
        if {[lsearch $keepFacList $fac] < 0} {
            set fac ""
        }

        # set sending facility
        lset fldList 3 $fac

        # Commit changes
        lset segList $segIndex [join $fldList $field_delim]
    }

    #=========================================================
    # PID formatter
    #=========================================================
    set segIndex [lsearch $segList "PID|*"]
    if {$segIndex>=0} {
        set fldList [split [lindex $segList $segIndex] $field_delim]
        _lextend "fldList" 30

        # put the  first in the PID-3 MRN field
        set fld [_FR_EPIC_OrderField [lindex $fldList 3] ""]
        lset fldList 3 $fld

        # Remove PID-5.7 patient name id and uppercase
        set ptName [join [lreplace [_lextend [split [string toupper [lindex $fldList 5]] $comp_delim] 7] 6 6 ""] $comp_delim]
        lset fldList 5 $ptName

        # uppercase these fields - race, lang, marstat, religion, ethnicity
        lset fldList 10 [string toupper [lindex $fldList 10]]
        lset fldList 15 [string toupper [lindex $fldList 15]]
        lset fldList 16  [string toupper [lindex $fldList 16]]
        lset fldList 17 [string toupper [lindex $fldList 17]]
        lset fldList 22 [string toupper [lindex $fldList 22]]

        #remove Race and Ethnicity for all but State immun. per regulations
        if {$msh8 != "VXU^V04"} {
            lset fldList 10 ""
            lset fldList 22 ""
        }

        # put csn from PV1-19 into PID-18
        lset fldList 18 $csn

        # Commit changes
        lset segList $segIndex [join $fldList $field_delim]
    }

    return $segList
}
#


######################################################################
# Name:        trxid_FR_EPIC_Routing
# Purpose:     Build and return trxid using facility and event type
# UPoC type:   trxid
# Args:     msgId = message handle
#           args  = (optional) user arguments
# Returns:  The message's transaction ID
#
# Notes:
#    The message is both modify- and destroy-locked -- attempts to modify
#    or destroy it will error out.
#
# Revisions:
#  03/07/2018 EMS Initial version

proc trxid_FR_EPIC_Routing { mh {args {}} } {
    global HciConnName                              ;# Name of thread
    set module "FR_EPIC_Routing/$HciConnName"          ;# Use this before every echo/puts
    set msgSrcThd [msgmetaget $mh SOURCECONN]       ;# Name of source thread where message came from
    ;# Use this before necessary echo/puts
    ;# args is keyed list when available

    set data [msgget $mh]                           ;# Message data
    set field_delim [string index $data 3]          ;# Field delimiter
    set comp_delim [string index $data 4]           ;# Component delimiter
    set rep_delim [string index $data 5]            ;# Repeat delimiter
    set segList [split $data "\r"]                  ;# Segments List
    set spacer "_"

    set fldList [split [lindex $segList 0] $field_delim]
    set sending_fac [string toupper [lindex $fldList 3]]
    set msgType [lindex [split [string toupper [lindex $fldList 8]] $comp_delim] 0]

    # determine the trxid
    set trxId $sending_fac$spacer$msgType

    return $trxId                ;# return it
}
#

