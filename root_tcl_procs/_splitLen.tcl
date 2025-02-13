if 0 {
    Descrition:
    This is a replacment for other_SplitNTEByLen. It can work on any string
    not just nte. This makes it more versitile, but more verbose to use.

    It takes a string and a max length, then returns a list with whole word
    splitting and trimming.

    Example:
    #=========================================================
    # Split OBX
    # Make a seperate section for godliness
    #=========================================================
    set segLen [expr [llength $segList]-1]                                                      ;# This count is done outside the loop because it increases
    for {set segIndex 0} {$segIndex<$segLen} {incr segIndex} {                                  ;# Do a regunlar for, a foreach with lsearch would return indexes that no longer are valid
    set fldList [split [lindex $segList $segIndex] $field_delim]                            ;# Split field
    if {[lindex $fldList 0]=="OBX"} {                                                       ;# If NTE
    # They need obxs to be max 200 char
    set split [_splitLen [lindex $fldList 5] 200]                                       ;# They need 80 char length, put 20 in to test
    if {[llength $split]>1} {                                                           ;# If the return list is longer than one, it had to split
    _lremove segList $segIndex                                                      ;# So remove this nte
    echo $split
    foreach content $split {                                                        ;# And insert a copy with the revised comment
        lset fldList 5 $content
        set segList [linsert $segList $segIndex [join $fldList $field_delim]]
        incr segLen                                                                 ;# Increment both the total segment count and the count we are currently on
        incr segIndex
    }
    incr segIndex -1
}
}
}

Change Log:
08/04/2013 -
-Removed nte pieces and modernized (rewrote) code
-This handles a string with no spaces now
-No loop back for spaces, simply string range
-Handles spaces at start or ends of line
-Infinite loop breakers
}

proc _splitLen { str maxLen {maxLoops 2000}} {
set rlist ""                    ;# The list to return
set str [string trim $str]      ;# Start off with a clean string
set strLen [string length $str] ;# The total length of sent in string
set pos 0                       ;# Start at the begining
set outerbreak $maxLoops        ;# Avoid infinite loops, no one is perfect

while 1 {
    set innerbreak $maxLoops
    while 1 {
        # Get the chunk, pull one extra character at the end to see if its a space
        set eor [expr {$pos+$maxLen}]
        set chunk [string range $str $pos $eor]

        # Loop until front has no spaces (either no spaces -1 or later spaces >=1)
        if {[string index $chunk 0]!=" "} { break; }
        incr pos

        # Safety brake for infinite loops
        incr innerbreak -1
        if {$innerbreak==0} {
            break
        }
    }

    # If our string is shorter to begin with we have reached the end
    # Add it to the list and break out, handle if it was trailing spaces
    if {$eor>=$strLen} {
        set chunk [string trim $chunk]
        if {$chunk!=""} {lappend rlist $chunk}
        break
    }

    set lastSpace [string last " " $chunk]
    if {$lastSpace==-1} {
        # No space was found trim off the last character
        set chunk [string range $chunk 0 end-1]

        # Add the maxlength as chunk should be that long
        incr pos $maxLen

    } elseif {$lastSpace == $maxLen} {

        # Add the maxlength as chunk should be that long
        incr pos $maxLen

    } else {
        # If the last character isnt a space, but by now we know there
        # is a space, cut to the space and after
        set chunk [string range $chunk 0 $lastSpace]

        # Even if we trimmed it off to shorter, we are counting as
        # having made it up to the lastSpace
        incr pos $lastSpace
    }

    # Add to return list, I wrapped in an if just to be safe.
    # Trimming here means it removes the trailing space for elseif block
    # it will also help if the else block returned a string with spaces
    # at the end.
    if {$chunk!=""} {lappend rlist [string trim $chunk]}

    # Safety brake for infinit loops
    incr outerbreak -1
    if {$outerbreak==0} {
        break
    }
}

return $rlist
}


