if 0 {
    _map collection iteratee
    iteratee item ?index? ?collection?
    item - current item of collection, typically abbriviated "o"
    index - index of current item in collection, typically abbriviated "i"
    collection - the entire collection, typically abbriviated "c"

    About:
    I wanted to have a lodash feature like map in tcl but obvi within
    confines of the language. We cant differentiate between lists and
    dicts so this proc requires a list. If you have a dict grab the values first.
    Other than that it is pretty faithful, even accepting a short-hand
    dict key name.

    Test Cases (examples):


    Cool Things:
    -This function can accept either 1,2,3 params without using "args"
    -Supports sending in just the key instead of requiring a anonymous function

    Change Log:
    10-17-2017 - TMH
    -Initial version
    -Test cases from lodash tested
    -Derived from http://www.tcl.tk/man/tcl8.5/TclCmd/apply.htm (example of map at bottom)
}
proc _map {list lambda} {
    # Start the result list and the index (which may not be used)
    set result {}
    set i -1

    # Determine if they used the short-hand method to grab a key
    set lambdaLen [llength $lambda]
    if {$lambdaLen==1} {
        set oldLambda $lambda
        set lambda {x {
            upvar oldLambda key
            return [dict get $x $key]}
        }
    }

    # For each item in collection apply the iteratee.
    # Dynamically pass the correct parameters.
    set paramLen [llength [lindex $lambda 0]]
    foreach item $list {
        set param [list $item]
        if {$paramLen>=2} {lappend param [incr i];}
        if {$paramLen>=3} {lappend param $list;}
        lappend result [apply $lambda {*}$param]
    }
    return $result
}