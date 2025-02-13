if 0 {
    Name:
    _keylToDict

    Purpose:
    Convert keylists to dictionaries (with string, list, etc)

    Param:
    Your keyed list

    Example:
    # You can define sub keyed lists seperate
    keylset subkey NAME.FIRST  NAME.MIDDLE  NAME.LAST
    keylset kl id 555 products [list 11 222 3333] details $subkey
    echo $kl
    echo [_keylToDict $kl]

    # Or you can do it by dot notation to dictate its parent
    keylset kl2 id 555 products [list 11 222 3333] details.NAME.FIRST  details.NAME.MIDDLE  details.NAME.LAST
    echo $kl2
    echo [_keylToDict $kl2]

    # Here I show using dict commands and that a list is correct maintained
    echo [dict get $d products] is [llength [dict get $d products]] long
    echo [dict get [dict get [dict get $d details] NAME] FIRST]

    History:
    2016-02-01
    - Initial version
}
#

proc _keylToDict {kl} {
    set d ""                                                ;# Create dict to build
    foreach k [keylkeys kl] {                               ;# Foreach key
    set val [keylget kl $k]                             ;# Get its value
    set keys ""                                         ;# Predefine keys
    catch {set keys [keylkeys val]}                     ;# Check if this is a keyed list by using keylkeys
    if {[llength $keys] > 0} {                          ;# If there was a keyed list
    dict append d $k [_keylToDict $val]             ;# Recursively loop until there are no more keyed lists
} else {
    dict append d $k $val                           ;# This wasnt a keyed list so just append it
}
}
return $d                                               ;# Return dictionary
}