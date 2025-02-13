if 0 {
    ClovertoolsV2 has a testing tool that I wanted to surpass both the ide and
    the origiinal clovertools. I want a clean json list of dict.
    
    The tcl service execs these two procs to get some predicatable formatted output.
    Then it parsed into a list of dictionaries to capture and return a clean object.
    
    Issues with ide:
        - Always scrolls to the bottom
        - Not much real estate
        - Errors not highlighted
        - No summary of all output
        - Cant jump to a specific message or error
    
    Issues with clovertools:
        - Inherited error barf from ide
        - Clunky manual parsing of output client and web server side, hard to tell
            where one ends and next begins, especially when an error occures
    
    Issues while coming to solution:
        - echos/puts go to stdout and are hard to capture    
    
    Notes of interest:
        - If there is an error in the tps proc it never calls the "send to proc"
        - hcitpstest is a compiled program, so you cant modify that

    Methods;
        1. (clovertools) clunky parser in web service c#
        2. clunky port of clunky parse in tcl webservice
        3. custom "send to proc" that better marked between echos and message, 
            slightly cleaner parsing in tcl service, as stated earlier custom
            "send to proc" never gets called in case of an error
        4. custom "send to proc" and custom tps proc which takes arg of real
            tps proc to test. Catch around that to ensure it always hits custom
            "send to proc"
}

proc _tpsResults { args } {
    set msgId [keylget args MSGID]
    set disp  [keylget args DISP]

    #The origianl hcitpstestshowbydisp line
    #echo [format "%8s: '%s'" $disp [msgget $msgId]]
    
    #echo 1 $args 1
    
    #Echos would have already be outputed
    #Then the errors and disp
    #And now we echo out the actual message
    echo ==CloverTools->message==
    puts [_baseEncode [msgget $msgId]]
    puts "==/CloverTools=="

    msgdestroy $msgId
}
proc _tpsExec { args } {
    #Get the script and remove it from the params
    set arg [keylget args ARGS ]
    set script [keylget arg SCRIPT]
    keyldel arg SCRIPT
    keylset args ARGS $arg
    keylget args MSGID mh

    #We dont need to exec in sub process, since we would
    #just echo it out anyway. But we do want to ensure any
    #errors are caught.
    set output ""
    set options ""
    set result ""
    catch {
        set output [$script {*}$args]
    } result options

    #Assume its an error, but if there was any output from
    # the script, overwrite its disp.
    set disp "ERROR"
    if {$output!=""} {set disp [lindex [lindex $output 0] 0]}
    
    #If we caught an error get it
    set err ""
    if {[dict exists $options "-errorinfo"]} {set err [dict get $options "-errorinfo"];}
    
    #By this point we have echos, echo the disp and err
    echo ==CloverTools->Disp/Err==
    echo [dict create \
        disp $disp \
        err [_baseEncode $err]
    ]
    
    #We always return continue to ensure it gets to the custom "send to proc" 
    lappend dispList "CONTINUE $mh"
}