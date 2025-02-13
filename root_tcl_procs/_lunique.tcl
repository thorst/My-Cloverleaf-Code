if 0 {
    set list [list 1 1 2 2 3 3]
    echo [_lunique $list]
}
proc _lunique {arg} {
    set d ""
    foreach k $arg {
        dict append d $k ""
    }
    return [dict keys $d]
}


