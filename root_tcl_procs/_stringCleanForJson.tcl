if 0 {
	
}
#

proc _stringCleanForJson {str } {
	return [string map {\" \\" "\r" "\\r" "\n" "\\n" "\t" "\\t"} $str]
}
#
