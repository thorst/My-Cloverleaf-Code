if 0 {
    _dictIs dict
        
    About:
        Test if string is a dictionary
    
    Change Log:
        10-17-2017 - TMH
            -Initial version, stole from tcl wiki
}
proc _dictIs {value} {
    expr {![catch {dict size $value}]}
}