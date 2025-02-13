if 0 {
    Name:
    _bldProv

    Arguments:
    data - The provider.
    index - The component where $provId should live.
    provId - The value that should be in that index.

    About:
    Epic needs certain assigning authority values in certain components depending on the field.  This is defined in ID Types in Epic.
    For example,
    "NPI" in the 13th component for doctors.
    "IMG" in THE 3rd component for the procedure.
    set ordProv [_bldProv [lindex $obrFlds 16] 13 $provId]
    set procSp [lreplace $procSp 2 2 $codeSys]
    Outcome =

    History:
    2016-07-15
    -initial version
}
proc _bldProv {data index provId} {
    set compDelim "^"
    set docSp [_lextend [split $data $compDelim] $index]
    set doc [join [lreplace $docSp [expr $index - 1] [expr $index - 1] $provId] $compDelim]
    return $doc
}

