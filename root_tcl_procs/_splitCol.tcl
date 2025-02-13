if 0 {
    https://stackoverflow.com/questions/5728656/tcl-split-string-by-arbitrary-number-of-whitespaces-to-a-list/5728880#5728880
    
      Splits a string based using another string
      Instead of a char
    
    Arguments:
      str       string to split into pieces.
    Results:
      Returns a list of strings
    
    Examples

}
proc _splitCol {str} {
    return [regexp -inline -all -- {\S+} $str]
}