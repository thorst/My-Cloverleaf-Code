if 0 {
    Name:
    _killNonAscii

    Arguments:
    val - The value sent from the calling proc.

    About:
    See History Revisions section.
    Since this proc loops through all characters in val,changes them to ascii, then evaluates them, i would try to send in small chunks.
    I wouldn't send in large fields, like obx5 or similar fields unitl you test the time it runs.
    History Revision:
    2018-01-26
    -initial version
    -used on note segments in  and .
    2021-02-11
    -changed the logic to regsub.  string is ascii was looked at too, but this seemed better.
    -used for address on .
    -^ denotes not in the class.  any character not in the class, substititue it with a blank. \x0 -\x7F covers the hex codes for the first 127 (non-extended ascii) characters.
    -x20 starts at space.  the values before it could send funky chs. so i kep them in the substitution part.  see http://www.asciitable.com/.
    -tested  and  with ascii 160 which was the original issue for that proc.
    -note, i added email logic to all procs that call this gloab if the values change.
}
proc _killNonAscii {val} {
    set val [regsub -all {[^\x20-\x7F]} $val ""]
    return $val
}
