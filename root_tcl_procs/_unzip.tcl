if 0 {
    2017-11-07 Steve
    -Initial version, started with _testFileFormat code
}
#

proc _unzip {{opts {}} args} {
    # Initialize options
    set opts [dict merge [dict create \
        filedir "" \
        filter "*" \
        ] $opts]

    # If directory, get all files that match filter
    if {[file isdirectory [dict get $opts "filedir"]]} {
        set files [glob -type f [dict get $opts "filedir"]/[dict get $opts "filter"]]
    } else {
        set files [list [dict get $opts "filedir"]]
    }

    foreach {file} $files {
        if {[file extension $file]==".gz"} {
            exec ksh -c "gunzip -N $file"
        }

    }
}
