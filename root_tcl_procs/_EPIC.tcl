#https:///Clovertools2/Tools/Yard?server=&stickid=3


if 0 {
    Script:
    EPIC_GetMaritalStatus string

    Description:
    Use the EPIC word abbreviation to lookup the legacy Marital Status code

    History:
    05/20/2016 -  -Initial version
}
#

proc EPIC_GetMaritalStatus {marstat} {
    set marstat [string toupper $marstat]

    dict append d "SINGLE" "S"
    dict append d "MARRIED" "M"
    dict append d "LEGALLY SEPA" "X"
    dict append d "DIVORCED" "D"
    dict append d "WIDOWED" "W"
    dict append d "SIGNIFICANT" "P"
    dict append d "UNKNOWN" "U"
    dict append d "OTHER" "U"

    return [_dictGet $d $marstat]
}
#



if 0 {
    Script:
    EPIC_GetRace string

    Description:
    Use the EPIC word abbreviation to lookup the legacy Race code

    History:
    05/20/2016 -  -Initial version
}
#

proc EPIC_GetRace {race} {
    set race [string toupper $race]

    switch $race {
        "" {set race "";}
        "NOT REPORTED" {set race "0";}
        "AM IND ALASK" {set race "1";}
        "ASIAN" {set race "2";}
        "BLACK" {set race "3";}
        "HAWI PAC ISL" {set race "4";}
        "WHITE" {set race "5";}
        "OTHER" {set race "7";}
        "UNKNOWN" {set race "8";}
        "DECLINED" {set race "9";}
        default {
            set race "7"
        }
    }

    return $race
}

#



if 0 {
    Script:
    EPIC_GetEthnicity string

    Description:
    Use the EPIC word abbreviation to lookup the legacy Ethnicity code

    History:
    05/20/2016 -  -Initial version
}
#

proc EPIC_GetEthnicity {ethnicity} {
    set ethnicity [string toupper $ethnicity]

    switch $ethnicity {
        "NOT REPORTED" {set ethnicity "0";}
        "HISPANIC" {set ethnicity "1";}
        "NOT HISPANIC" {set ethnicity "2";}
        "UNKNOWN" {set ethnicity "8";}
        "DECLINED" {set ethnicity "9";}
        default {
            set ethnicity ""
        }
    }

    return $ethnicity
}
#



if 0 {
    Script:
    EPIC_GetLanguage string

    Description:
    Use the EPIC word abbreviation to lookup the legacy Language code

    History:
    05/20/2016 -  -Initial version
}
#

proc EPIC_GetLanguage {lang} {
    set lang [string toupper $lang]

    switch $lang {
        "" {set lang "";}
        "NOT REPORTED" {set lang "0";}
        "SPA" {set lang "1";}
        "ENG" {set lang "2";}
        "DECLINE" {set lang "9";}
        default {
            set lang "7"
        }
    }

    return $lang
}

#



if 0 {
    Script:
    EPIC_GetMRN listName ?mrntype?
    listName is the entire PID-3 field
    mrntype is optional and defaults to MRN

    Description:
    Pull out the desired MRN from the EPIC transaction field

    Example:
    Call this routine like so with PID-3 or MRG-1 identifiers
    get the YH MRN
    set mrn [EPIC_GetMRN [lindex $fldList 3]]
    get an different MRN
    set mrn [EPIC_GetMRN [lindex $fldList 3] "GH"]

    History:
    05/20/2016 -  -Initial version
}
#
proc EPIC_GetMRN {mrnList {mrntype "MRN"} {comp_delim "^"} {rep_delim "~"}} {
    foreach fld [split $mrnList $rep_delim] {
        set newList [split $fld $comp_delim]
        if {[lindex $newList 4]==$mrntype} {
            return [lindex $newList 0]
        }
    }

    return ""
}

#



if 0 {
    Script:
    EPIC_GetPHONE listName ?phtype?
    listName is the entire PID-13 field
    phtype is optional and defaults to H as home phone

    Description:
    Pull out the desired phone item from the EPIC transaction field

    Example:
    Call this routine like so with PID-13 home phone field
    get the home phone
    set ph [EPIC_GetPHONE [lindex $fldList 13]]
    get the mobil phone
    set ph [EPIC_GetPHONE [lindex $fldList 13] "M"]
    get the email address
    set ph [EPIC_GetPHONE [lindex $fldList 13] "Internet"]

    History:
    05/20/2016 -  -Initial version
}
#
proc EPIC_GetPHONE {phList {phtype "H"} {comp_delim "^"} {rep_delim "~"}} {
    foreach fld [split $phList $rep_delim] {
        set newList [split $fld $comp_delim]
        if {[lindex $newList 2]==$phtype} {
            return [lindex $newList 0]
        }
    }

    return ""
}

#



if 0 {
    Definition:
    EPIC_GetProv listName ?provtype? ?comp_delim? ?rep_delim?
    listName is the entire provider field
    provtype is which number to extract, is optional and defaults to NPI. Possible: WHPROVID,NPI,SERID
    comp_delim is optional and defaults to ^
    rep_delim is optional and featuls to ~

    Description:
    Pull out the desired Provider from the EPIC transaction field

    Example:
    Call this routine like so with any of the provider fields
    get the NPI
    set prov [EPIC_GetProv [lindex $fldList 3]]
    get a different Provider ID
    set prov [EPIC_GetProv [lindex $fldList 3] "WHPROVID"]

    History:
    10/03/2016 -
    - Initial version
    11/08/2017 - thorst2
    - Added support for repeating fields
    - Ensures list is unique (based on comp 0), some transactions were coming out with dupe providers
}
#
proc EPIC_GetProv {provList {provtype "NPI"} {comp_delim "^"} {rep_delim "~"}} {
    set newList ""
    foreach fld [split $provList $rep_delim] {
        set cmp [split $fld $comp_delim]
        if {[lindex $cmp 12]==$provtype} {
            dict set newList [lindex $cmp 0] $fld
        }
    }
    return [join [dict values $newList] $rep_delim]
}
#



