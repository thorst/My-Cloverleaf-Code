if 0 {
    Name:
    _keylget

    Arguments:
    kl - A keyed list, either the value or the variable name
    arg - The key you wish to retrieve

    About:
    It first checks to see if its a keyed list. If it is it tries to do a
    keylget. If it isnt it tries to upvar to gain the reference (syntax used by keylget).
    If any errors are encountered it returns an empty string instead of an error.

    History:
    2016-02-02
    -initial version
}
#

proc _keylget {kl arg {default ""}} {

    #set keys ""                             ;# Predefine keys
    #catch {set keys [keylkeys kl]}          ;# Check if this is a keyed list by using keylkeys
    #if {[llength $keys] == 0} {             ;# If there wasnt a keyed list
    #    set tmpkl $kl                       ;# Backup kl name
    #    unset kl                            ;# Remove kl otherwise we cant upvar
    #    upvar $tmpkl kl                     ;# Gain reference
    #}

    # Cheaper hack to test for keyed list, gotta start with squrily
    if {[string range $kl 0 0] != "\{"} {   ;# If there wasnt a keyed list
    set tmpkl $kl                       ;# Backup kl name
    unset kl                            ;# Remove kl otherwise we cant upvar
    upvar $tmpkl kl                     ;# Gain reference
}

set ret $default                              ;# Predfine return value
catch {set ret [keylget kl $arg]}       ;# Get value
return $ret                             ;# Return value
}
