if 0 {
    Given a site and cloverlefa table NAME, convert values to a dictionary
    
    History-
        08/31/2017 - TMH - 
            - Taking a stab at converting a cloverleaf table to a dictionary
}

proc _tblToDict {site table} {
    global env
    
    # File Path
    set file "$env(HCIROOT)/$site/Tables/$table.tbl"
    
    # Read file
    set fl [open $file]
    set data [read $fl]
    if {[catch {close $fl} err]} {
        puts "ls command failed: $err"
    }
    
    # Build dictionary from table file
    set d ""
    foreach g [split $data \#] {
        set dList [split $g \n]
    
        if {[string range [lindex $dList 3] 0 6]=="encoded"} {
            dict set d [lindex $dList 1] [lindex $dList 2]
        }
    }
    
    # Return dicitonary
    return $d
}