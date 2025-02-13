if 0 {
    Param:
    Purpose:
    
    Links:
    http://core.tcl.tk/tcllib/doc/trunk/embedded/www/tcllib/files/modules/base64/base64.html
}
#
package require base64
proc _baseEncode {string {maxlen 0} {wrapchar "\n"}} {
    return [::base64::encode -maxlen $maxlen -wrapchar $wrapchar $string]
}
#

proc _baseDencode {string} {
    return [::base64::decode $string]
}