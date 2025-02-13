if 0 {
    Name:
    _killDoc

    Arguments:
    val - The value sent from the calling proc.

    About:

    History:
    2018-03-16
    -initial version
}
proc _killDoc {proc} {
    set procList [list "" "" "" "" ""]
    if {[lsearch $procList $proc] > -1} {
        return true
    }
    return false
}
