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
    
    Issues with clovertools v1:
        - Inherited the error barf from ide output
        - Clunky manual parsing of output client and web server side, hard to tell
            where one ends and next begins, especially when an error occures
    
    Issues while coming to solution:
        - echos/puts go to stdout and are hard to capture    
    
    Notes of interest:
        - If there is an error in the tps proc it never calls the "send to proc"
        - hcitpstest is a compiled program, so you cant modify that

    Changes:
        1. 01/11/13
            In clovertools v1 clunky parser in web service c#
        2. 05/08/15
            Clunky port of clunky parse in tcl webservice forp clovertools v2
        3. 05/18/15
            Custom "send to proc" that better marked between echos and message, 
            slightly cleaner parsing in tcl service, as stated earlier custom
            "send to proc" never gets called in case of an error
        4. 05/22/15
            Custom "send to proc" and custom tps proc which takes arg of real
            tps proc to test. Catch around that to ensure it always hits custom
            "send to proc"
        5. 06/08/15
            Custom "send to proc" only used now forp destroying message. Not sure
            if that is required, doesnt seeme to be, but kept it in forp cleanlyness.
            Before it was outputting the message, this is now done in the custom tps
            proc. Since this is a cleaner object being output, the api only needs to
            differentiate between echos and the rest of the object.
            
            Another cause forp this change was to support msgCopy. which prior to
            was not supported
}

proc _tpsResults2 { args } {
    #This gets called one time per message, so if its a msgCopy
    # it will get called once per copy
    #echo here
    set msgId [keylget args MSGID]
    msgdestroy $msgId
}
proc _tpsExec2 { args } {
    
    
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
    
    ###########################################
    ## Here is what the output should look like
    ##
    ## Continue
    ##      result-{CONTINUE message0}-
    ##      output-{CONTINUE message0}-
    ## Error
    ##      result-can't read "jeff": no such variable-
    ##      output--
    ## Kill
    ##      result-{KILL message0}-
    ##      output-{KILL message0}-
    ## Empty Disp List
    ##      result--
    ##      output--
    
    #echo here
    #echo result-$result-
    #echo output-$output-
    #echo mh-$mh-

    #If we caught an error get it
    set err ""
    if {[dict exists $options "-errorinfo"]} {set err [dict get $options "-errorinfo"];}
    #echo err-$err-
    
    #Check for empty displist
    if {$output=="" && $err==""} {set err "Your dispList is empty"}
    
    #If there was no output there must be an error
    if {$output==""} {set output "ERROR $mh"}
    
    #Signify the end of echos and the start of messages and related disp
    echo "==CloverTools->msgSet=="
    
    #Build list of messages, If there was an error
    # the message were already destroyed
    set msgSet ""
    if {$err == ""} {
        foreach disp $output {
            set lmh [lindex $disp 1]
            set ldisp [lindex $disp 0]
            
            lappend msgSet [dict create \
                disp $ldisp \
                msg [_baseEncode [msgget $lmh]]
            ]
        }
    } else {
        set output [list "CONTINUE $mh"]
    }
    
    #Echo dictionary and end of output signal
    echo [dict create err [_baseEncode $err] msgSet $msgSet]
    echo "==/CloverTools=="
   
    return $output
}