if 0 {
    http://code.activestate.com/recipes/68386-multi-character-split/
    mcsplit --
    
      Splits a string based using another string
      Instead of a char
    
    Arguments:
      str       string to split into pieces
      splitStr  substring
      mc        magic character that must not exist in the orignal string.
                Defaults to the NULL character.  Must be a single character.
    Results:
      Returns a list of strings
    
    Examples
        Basic example:
        set u "split by string"
        echo [_split $u "by"]
        >> {split } { string}

        I wanted to split while ignoring spaces. I found/came up with two options.
        The first uses a regular expression to treat all whitespace the same. The 
        second has you manually removing crlf, then using this _split and then 
        removing empty strings. You could choose either of these methods:
        1) set strList [regexp -all -inline {\S+} $u]
        2) set my [_lremoveVals [_split [string map {\n " " \r " "} $u] " "] "\{\}"]
}
proc _split {str splitStr {mc \x00}} {
    return [split [string map [list $splitStr $mc] $str] $mc]
}