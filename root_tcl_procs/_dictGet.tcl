if 0 {
    Name:
        _dictGet ?options? dictionaryValue ?key ...?
    
    Options:
        -default defaultValue
            Choose the default value to be returned if key is not found. Default is "".
        
    Description:
        Instead of throwing an error, return a value when a key does not exist.
        You can use this to pull a key from nested dictionaries just as you can 
            [dict get]
    
    Example:
        set myDict [dict create Key1 Val1 Key2 [dict create SubKey1 SubVal1]]
        echo Key1 Value:[_dictGet $myDict Key1]                                         ;# Basic example pulling a key that does exist
        echo Key3 Value:[_dictGet $myDict Key3]                                         ;# Basic example pulling a key that doesn't exist
        echo Key2>SubKey1 Value:[_dictGet $myDict Key2 SubKey1]                         ;# Subkey example that does exist
        echo Key2>SubKey1 Value:[_dictGet $myDict Key2 SubKey2]                         ;# Subkey example that doesn't exist
        echo Key1 Value:[_dictGet -default false $myDict Key1]                          ;# Default return example pulling a key that does exist
        echo Key3 Value:[_dictGet -default false $myDict Key3]                          ;# Default return example pulling a key that doesn't exist
        echo Key2>SubKey1 Value:[_dictGet -default false $myDict Key2 SubKey2]          ;# Default return Default return pulling Subkey example that doesn't exist
        
        >>Key1 Value:Val1
        >>Key3 Value:
        >>Key2>SubKey1 Value:SubVal1
        >>Key2>SubKey1 Value:
        >>Key1 Value:Val1
        >>Key3 Value:false
        >>Key2>SubKey1 Value:false
    
    History:
        05/13/2016 TMH
            -Replaces _dictTryGet - try in name isnt needed
            -Added default return
}
proc _dictGet {args} {
    set result ""
    if {[lindex $args 0]=="-default"} {
        set result [lindex $args 1]
        _lremove args [list 0 1]
    }
    set userDict [lindex $args 0] 
    _lremove args 0
    catch {set result [dict get $userDict {*}$args]}
    return $result
}


