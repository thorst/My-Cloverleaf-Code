if 0 {
    2017-11-07 Steve
    -Initial version, started with _testFileFormat code
}
#

proc _zip {{opts {}} args} {
    # Initialize options
    set opts [dict merge [dict create \
        filedir "" \
        filter "*" \
        appendEpoch false \
        ] $opts]

    # If directory, get all files that match filter
    if {[file isdirectory [dict get $opts "filedir"]]} {
        set files [glob -type f [dict get $opts "filedir"]/[dict get $opts "filter"]]
    } else {
        set files [list [dict get $opts "filedir"]]
    }

    set TIME_start [clock clicks -milliseconds]
    foreach {file} $files {
        if {[file extension $file]!=".gz"} {
            if {[dict get $opts "appendEpoch"]} {
                exec ksh -c "gzip -S.$TIME_start.gz -9 $file"
            } else {
                exec ksh -c "gzip -9 $file"
            }
        }

    }
}
