if 0 {
    The new server scheme takes us from 2 to 12 servers. And evnrinmoent is more
    than test and prod. We have a semi naming convention here and are able to
    use that to make inteligent guesses.
}
#



if 0 {
    About:
    This function correctly handles all the new servers. It doesnt handle the old servers well,
    so I have a 2 if hack to handle that.

    It needs to return a list of 3 segments,
    1. Type ex MAIN
    2. Env ex PRD
    3. Number ex 01

    History:
    2016-02-03
    -Initial Version
    2017-07-12
    -Fixed isTTool. Ouside engine check was returning 1 instead of 0.
}
proc _serverSplit {arg} {
    #Take the one they gave you, but if its empty use the real hostname
    if {$arg==""} {
        set arg [_serverName]
    }
    set arg [string tolower $arg]

    # This is an old  or  server
    if {$arg == ""} { return [list "" "prd" "1"]; }
    if {$arg == ""} { return [list "" "tst" "1"]; }

    # Return the three parts
    return [list [string range $arg 2 end-5] [string range $arg end-4 end-2] [string range $arg end-1 end]]
}
#


if 0 {
    About:
    Instead of reapeating myself in each proc, the testEnv proc
    will allow me to test against a string, or test inverse

    History:
    2016-02-03
    -Initial Version
}
proc _serverTestEnv {arg comp {inverse false}} {
    set shn [_serverSplit $arg]

    if {$inverse} {
        if {![string equal [lindex $shn 1] $comp]} {return true}
    } else {
        if {[string equal [lindex $shn 1] $comp]} {return true}
    }

    return false
}
#


if 0 {
    About:
    Here are a group of comparisons to see what environment we are in.
    These all return boolean.

    History:
    2016-02-03
    -Initial Version
    2016-08-04
    -_isTTool failed if outside of engine (fiddle), now it returns true
}
proc _isProd {{arg ""}} {
    return [_serverTestEnv $arg "prd"]
}
proc _isNonProd {{arg ""}} {
    return [_serverTestEnv $arg "prd" true]
}
proc _isBuild {{arg ""}} {
    return [_serverTestEnv $arg "bld"]
}
proc _isPOC {{arg ""}} {
    return [_serverTestEnv $arg "poc"]
}
proc _isTest {{arg ""}} {
    return [_serverTestEnv $arg "tst"]
}
proc _isTrain {{arg ""}} {
    return [_serverTestEnv $arg "trn"]
}
proc _isTTool {} {
    global HciConnName
    if {![info exists HciConnName]} {return 0;}
    return [expr {$HciConnName=="TEST"}]
}
#


if 0 {
    About:
    Return just the piece they ask for.
    These all return string

    History:
    2016-02-03
    -Initial Version
}
proc _serverEnv {{arg ""}} {
    return [lindex [_serverSplit $arg] 1]
}
proc _serverType {{arg ""}} {
    return [lindex [_serverSplit $arg] 0]
}
proc _serverNum {{arg ""}} {
    return [lindex [_serverSplit $arg] 2]
}
proc _serverName {} {
    return [lindex [split [exec hostname] "."] 0]
    #return [info hostname]
}
#

