proc _smatCycle {site process thread} {

    # Initialize response
    set response [dict create \
        in true \
        out true \
        error "" \
        successful true \
    ]
    
    # Set site appropriately
    _siteSet $site
    
    # Cycle in
    set reply [exec hcicmd -p $process -c "$thread save_cycle in"]
    if {$reply!="Response:\nsaving of inbound messages is not active\n" && $reply!="Response:\ninbound message saving cycled\n"} {
        dict set response successful false
        dict set response in false
        dict set response error $reply
    }
    
    # Cycle out
    set reply [exec hcicmd -p $process -c "$thread save_cycle out"]
    if {$reply!="Response:\nsaving of outbound messages is not active\n" && $reply!="Response:\noutbound message saving cycled\n"} {
        dict set response out false
        dict set response successful false
        dict set response error "[dict get $response error]\n$reply"
    }
    
    
    return $response
}

