if 0 {
    Param:
        fromDate - int - REQUIRED - seconds from epoch
        toDate   - int - OPTIONAL - seconds from epoch
        
        epoch time is defined as 1 January 1970, 00:00 UTC
    
    Purpose:
        Given a date, determine the difference based on current datetime
        Given two dates, determine the difference between them
    
    Fiddle:
        set date [clock scan 20010910]
        set d  [_dateDiff $date]
        echo $d
        echo [expr {floor([dict get $d years])}]
        >> seconds 434455653 minutes 7240927.55 hours 120682.12583333332 days 5028.421909722222 years 13.77649838280061 roundyears 14
        >> 13.0
        
        set date [clock scan 20010410]
        echo [_dateDiff $date]
        echo [_dateDiff $date [clock add $date 100 days]]
        echo [_dateDiff $date [clock add $date -100 minutes]]
        echo [_dateDiff $date [clock add $date -4 years]]
        >> seconds 447674853 minutes 7461247.55 hours 124354.12583333332 days 5181.421909722222 years 14.19567646499239 roundyears 14
        >> seconds 8640000 minutes 144000.0 hours 2400.0 days 100.0 years 0.273972602739726 roundyears 0
        >> seconds -6000 minutes -100.0 hours -1.6666666666666667 days -0.06944444444444445 years -0.00019025875190258754 roundyears 0
        >> seconds -126230400 minutes -2103840.0 hours -35064.0 days -1461.0 years -4.002739726027397 roundyears -4
        
        # Invalid date returned from clock scan
        set dob "20150715000000"
        set parse1 [clock scan $dob]
        set parse2 [clock scan $dob -format "%Y%m%d%H%M%S"]
        echo $parse1
        echo $parse2
        echo [_dateDiff $parse1]
        echo [_dateDiff $parse2]
        >> -4011837966238
        >> 1436932800
        >> seconds 4013287563158 minutes 66888126052.63333 hours 1114802100.8772223 days 46450087.53655093 years 127260.51379876968 roundyears 127261
        >> seconds 12664120 minutes 211068.66666666666 hours 3517.811111111111 days 146.57546296296297 years 0.4015766108574328 roundyears 0
    
    History:
        06/16/2015 Todd H
            -Initial version
        06/17/2015 Todd H
            -Renamed _dateDiff instead of _dateAge
            -Allow 2nd param instead of assuming NOW
            -Added seconds, minutes, hours, and days
            -Removed floor years
        12/08/2015 Todd H
            -Note about passing in clock scan format
}
#

proc _dateDiff {fromDate {toDate ""}} {
    if {$toDate == ""} {
        set toDate [clock seconds]    
    }
    
    set seconds [expr {$toDate-$fromDate}]
    set minutes [expr {$seconds/60.0}]  
    set hours [expr {$minutes/60.0}]
    set days [expr {$hours/24.0}]
    set years [expr {$days/365.0}]
    
    return [dict create \
            seconds $seconds \
            minutes $minutes \
            hours $hours \
            days $days \
            years $years \
            roundyears [expr {round($years)}]
    ]
}