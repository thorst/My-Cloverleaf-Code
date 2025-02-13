if 0 {
    Name:
    _epicDisclaimer

    Arguments:
    segments - the hl7 msg from the calling procs.
    HciConnName - should be the thread name in a working environment, not testing tool.

    About:
    Per April MM 2022 - Nov. 2021  - 820400 Nova Note, if &DIS is sent in the first instance of OBX, email the team.
    R AIF 940 was updated with &DIS for this note-workflow.
    Epic doesn't know the workflow to test this, so we can't truely test what they say will happen.  Therefore, we coded to get an email if "&DIS" is in any OBX:3.
    Cloverleaf Procs (Bridges interface):
    RADORD_FR_EPIC (839310)
    CARDORD_FR_EPIC (839312, 839326)
    GENRES_FR_EPIC (839314)
    GIORD_FR_EPIC (839316)
    History:
    2022-03-15
    -initial version
    2022-05-11
    -After being live for a few months, we decided we don't need to know about either of the instances Epic sends these DIS values.
    -   We've seen the note work in some Radiant workflows and all is good. Sue did extensive research.
    -   Cupid has been sending a disclaimer for years as designed for Summit, which is diff. than the note changes.

}
proc _epicDisclaimer {segments HciConnName} {
    # get 1st instance of OBX segment.
    set obxIndex [lsearch $segments "OBX|*"]
    set obxFlds [_lextend [split [lindex $segments $obxIndex] "|"] 5]

    # get the report of the 1st instance of OBX.
    set obx3 [lindex $obxFlds 3]
    set report [lindex $obxFlds 5]

    # If 1st OBX has &DIS and not one of the above canned messages, email the team.
    if {[string equal $obx3 "&DIS"] && ![regexp {Result is being edited|This is a summary report} $report]} {
        set to [join [list "@.org" "@.org" "@.org"] ","]
        set from "@.org"
        set subject "$HciConnName Disclaimer"
        set body $segments
        _Email [dict create \
            to $to \
            from $from \
            subject $subject \
            body [list \
                [dict create content [join $body "\r\n"]] \
                [dict create content "<b>[join $body "<br/>"]</b>" type "text/html"] \
            ]
        ]
    }
}
