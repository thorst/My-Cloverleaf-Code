if 0 {
    Param:
        printer -   The name of the printer you would like to print to.
                    Must be installed locally
         
        jobs -      List of dictionaries with EITHER a content OR a
                    file key.
    
    Purpose:
        Easily print 1 or more strings or files
    
    Example:
        #Create my string
        set myVar "Hello Todd Horst"
        
        #Print my string
        _Print comm2 [list \
                        [dict create content $myVar] \
                        [dict create file /qdxiprod/cis6.1/integrator/tclprocs/_BASE.tcl]
                    ]
    
    Change Log:
    04/28/2015 Todd Horst
        - Initial version
    05/04/2015 Todd Horst
        - Ability to send to mulitple printers
	
	Current printers are:
         mr13
         bb3
}
#

proc _Print {printers jobs} {
    foreach p $printers {
        foreach j $jobs {
            if {[dict exist $j content]} {
                exec lpr -h -P $p << [dict get $j content]
            } elseif {[dict exists $j file]} {
                exec lpr -h -P $p <<< [dict get $j file]
            }
        }
    }
    
    return 
}
#