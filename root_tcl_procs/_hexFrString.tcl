if 0 {
    This is a quick tool to take a hex string and turn it 
    into the actual hex
    
    Example:
        echo [_hexFrString "A9"]
}
proc _hexFrString {hex} {
    return [binary format H* $hex]
}