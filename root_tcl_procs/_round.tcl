if 0 {
    _round value ?decimals?
        value - some numeric value with decomal places
        decimals - the number of decimals to return, default to two
        
    Purpose:
        Easy way for you to round numbers
    
    Links:
    
    Change Log:
        10/25/2017 - tmh
            -Added to parameter borrowed from the comment here: https://stackoverflow.com/a/10212642
}
#

proc _round {val {to 2}} {
    expr {round(10**$to*$val)/10.0**$to}
}