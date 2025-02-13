if 0 {
    _pidSearch ?opts?

    About:
    pid search can search the running processes and return data about them

    General Info:
    f options are filtering
    o options are output

    Options:
    term - The term you are searching for, will search entire line, not just the cmd text
    f>Day - Operator: >= Values: 1 to infiniti (and beyond) (More efficient)
    f>Hour - Operator: >= Values: 1 and 23 (Less efficient)
    f>CPU - Operator: >= Values: 1 to 100
    f>RAM - Operator: >= Values: 1 to 100
    oCMD - Default: false - Determines whether to include the name of the command, which can be lengthy

    Example:
    _pidSearch                                              ;# Return all running processes
    _pidSearch [dict create term ".*"]                      ;# Use a regular expression to filter
    _pidSearch [dict create term "lm .*$site "]             ;# Search for any process mentioning lm then space, then any number of characthers and then the site name and space
    _pidSearch [dict create term "api/tclEval.tcl -run"]    ;# Use a string to filter
    _pidSearch [dict create term "bin" f>Hour 1]            ;# Only thouse that have been running for an hour
    _pidSearch [dict create f>RAM 1]                        ;# Processes using >= 1% of ram
    _pidSearch [dict create term "hcimonitord -S $"];# Ensure that  is at the end of the string

    Help:
    https://stackoverflow.com/a/1069333

    Seasrching
    By default it searches anywhere on the string so 'hcimonitord -S ' on  will return  as well as , , ,
    In order to fix this leverage the regular expression aspect of grep and search instead for 'hcimonitord -S $'

    Change Log:
    09/08/2017 - TMH
    -Initial version
    10/16/2017 - TMH
    -Rewite to allow dict in/out
    -Added day,hour,cpu,ram filters
    -Added optional cmd output
}

proc _pidSearch {{opts {}} args} {
    # Initialize options
    set opts [dict merge [dict create \
        term "" \
        f>Day "" \
        f>Hour "" \
        f>CPU "" \
        f>RAM "" \
        oCMD false \
        ] $opts]

    # Build list of filters included by the user
    # Typically Im against crazy awks and execs, but I'm trying to limit the amount
    #  of data tcl even has to worry about
    set filters ""
    if {[dict get $opts "term"]!=""} {
        lappend filters "| grep -- '[dict get $opts term]'"
    }
    if {[dict get $opts "f>Day"]!=""} {
        lappend filters "| awk 'int(substr(\$5,1,index(\$5,\"-\"))) >= [dict get $opts "f>Day"] \{ print \}'"
    }
    if {[dict get $opts "f>Hour"]!=""} {
        # This one echos the output so you can see how its making descisions
        #append filters "| awk '\{split(\$5,a,\":\");la=length(a);split(a\[1\],b,\"-\");lb=length(b);  if (la == 3 && lb == 2) print \$5,\"yes\"; else if (int(a\[1\])>=[dict get $opts "f>Hour"]) print \$5,\"yes\"; else print \$5,\"no\";  \}'"
        lappend filters "| awk '\{split(\$5,a,\":\");la=length(a);split(a\[1\],b,\"-\");lb=length(b);  if (la == 3 && lb == 2) print; else if (int(a\[1\])>=[dict get $opts "f>Hour"]) print;  \}'"
    }
    if {[dict get $opts "f>CPU"]!=""} {
        lappend filters "| awk 'int(\$6) >= [dict get $opts "f>CPU"] \{ print \}'"
    }
    if {[dict get $opts "f>RAM"]!=""} {
        lappend filters "| awk 'int(\$7) >= int([dict get $opts "f>RAM"]) \{ print \}'"
    }

    # Execute the command
    set results ""
    catch {set results [exec ksh -c "ps x -eo pgid,ppid,pid,user,etime,%cpu,%mem,args | grep -v grep [join $filters]"]}

    # Build the result list
    set o ""
    foreach l [split $results \n] {
        set cols [_splitCol $l]

        #set pgid [lindex $cols 0]      ;#Pid group id
        #set ppid [lindex $cols 1]      ;#Pid parent id
        set pid [lindex $cols 2]        ;#Pid
        set user [lindex $cols 3]       ;#User
        set etime [lindex $cols 4]      ;#Age
        set cpu [lindex $cols 5]        ;#Cpu % usage
        set mem [lindex $cols 6]        ;#Mem % usage
        set cmd [lrange $cols 7 end]    ;#Command

        # Format age to be consistent
        set age [split $etime ":"]
        if {[llength $age]==2} {
            set etime 0-00:$etime
        } elseif {[llength $age]==3 && [llength [split [lindex $age 0] "-"]]==1} {
            set etime 0-$etime
        }

        # Build Dict
        set d [dict create \
            pid $pid \
            user $user \
            etime $etime \
            cpu $cpu \
            mem $mem \
        ]

    # Optionally include cmd, this can be long
    if {[dict get $opts "oCMD"]} {
        dict set d cmd $cmd
    }

    # Add to list
    lappend o $d
}

return $o
}