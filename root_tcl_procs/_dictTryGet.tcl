if 0 {
    Name:
        _dictTryGet
        
    Description:
        Instead of throwing an error, return an
        empty stirng when a key does not exist
    
    Example:
        set d [dict create 1 test 2 [dict create yo wow]]
        echo 2 yop -- [_dictTryGet $d 2 yop]
        echo 2 yo -- [_dictTryGet $d 2 yo]
}
proc _dictTryGet {d args} {
    echo _dictTryGet is depricated. Please use _dictGet
    set result ""
    catch {set result [dict get $d {*}$args]}
    return $result
}

