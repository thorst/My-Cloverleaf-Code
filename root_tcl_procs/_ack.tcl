######################################################################
# Name:         tps_Generic_ACK
#
# Purpose:      This procedure sends a reply message to the sending system.
#               If the ACK_OVERRIDE parameter is set, override using "ACK" in the MSH:8 in
#               the reply message. Default to ACK if no parameter or the message type is
#               not found in the ACK_OVERRIDE list.
#
# UPoC type:    tps
#
# Args:         tps keyedlist containing the following keys:
#               MODE    run mode ("start", "run" or "time")
#               MSGID   message handle
#               ARGS    user-supplied arguments:
#                       ACK_OVERRIDE: List "ACK" overrides, e.g., "{ORM:ORR} {MFN:XYZ}"
#                           so ORM messages return ORR, MFNs return XYZ, and all else still return ACK
#                       ACK_CODE: List "ACK" code overrides, e.g., "{ORM:AA} {MFN:CA} {*:AA}"
#
# Returns:      tps disposition list:
#               <describe dispositions used here>
#
# Notes:        This function was "borrowed" from  and
#               modified by Todd  and Mike  for
#               use by
#
# Revisions:
# Date        Editor    Description
# ----------  --------  --------------------------------------------------
# 07/08/2003  Steve    -Add a carriage return (\r) to the end of the MSA segment.
# 12/09/2003  Todd     -Removed MSA:4 - If message type is ORM, set MSH:8 to ORR, otherwise, set MSH:8 to ACK.
# 01/12/2004  Roger    -Replaced the ORR vs. ACK logic: use the ACK_OVERRIDE parameter.
# 05/10/2015  Todd     -Cleaned up formatting
#                       -Added 1 line of code to allow multiserver, tried emdeons method and that didnt work
#                       -Fixed switch default was under time
#                       -Cleaned up reply message creation
#                       -Removed leftovers variable as it was unused
# 03/28/2016  Todd     -Renamed _ack and pulled out of shared routines
# 10/06/2016  Todd     -Testing out allowing ack code overrides, some clients want CA instead of AA
#
# Multiserver:
# 1. Check the box in multiserver config "Save client IP and port to driver control" and then add the following
#    code. This was taken from clovertech - http://clovertech.infor.com/viewtopic.php?t=7081&highlight=mutliserver+ack
#       set ackmsgDriverCtl [msgmetaget $mh DRIVERCTL]
#       msgmetaset $ackmh DRIVERCTL $ackmsgDriverCtl
#
# 2. Emdeon (through Hanover results interface) uses cloverleaf and gave me the following lines.
#       # following required for multiserver communications
#       # set some key meta data fields from the source message
#       msgmetaset $obMsg DESTCONN [msgmetaget $mh ORIGSOURCECONN]
#       msgmetaset $obMsg SOURCECONN [msgmetaget $mh DESTCONN]
#
# 3.  method is to not check the box to save ip/port to driverctrl and add:
#       msgmetaset $ackmh DRIVERCTL [msgmetaget $mh DRIVERCTL]
#
#
proc _ack { args } {
    keylget args MODE mode                                          ;# Fetch mode
    set dispList {}                                                 ;# Nothing to return
    switch -exact -- $mode {
        start {
        }

        run {
            keylget args MSGID mh                                   ;# Comments by MDM
            set data [msgget $mh]                                   ;# Message Data
            set field_delim [cindex $data 3]                        ;# Message Field delimiter
            set comp_delim [cindex $data 4]                         ;# Message Component delimiter
            set split_data [split $data "\r"]                       ;# Split message into list of segements
            set MSH [lindex $split_data 0]                          ;# Get MSH segement always index 0
            set split_MSH [split $MSH $field_delim]                 ;# Split MSH seg into list of fields

            # Fill the following variables with the fields of the MSH segement
            # {header encode snd_app snd_fac rec_app rec_fac data_time sec msg_type mcid pid vid seq}
            lassign $split_MSH header encode snd_app snd_fac rec_app rec_fac data_time sec msg_type mcid pid vid seq

            # Create the data for the outbound reply message
            set reply_time [clock format [clock seconds] -format "%Y%m%d%H%M%S"]   ;# Create the reply time

            set reply_ID [clock clicks]                                     ;# (MDM) Generate unique ID
            if {$reply_ID < 0} { set reply_ID [expr $reply_ID * -1]}        ;# and make sure it is not negative

            # Get message type
            set msg_type [string range $msg_type 0 2]

            # Get user args keyed list
            keylget args ARGS uargs

            # See if the user passed a value.  If not just use ACK.
            # keylget will not affect the variable if the key doesn't exist.
            set replace_ack ""
            keylget uargs ACK_OVERRIDE replace_ack

            # Use ACK as the default ACK.
            # Allow overrides via the parameter, e.g., "ORM:ORR MFN:XYZ"
            # so ORM messages return ORR, MFNs return XYZ, and all else still return ACK.
            set ack ACK
            if {[string length $replace_ack] != 0} {
                set replace_index [lsearch $replace_ack "$msg_type:*"]
                if {$replace_index != -1} {
                    set ack [lindex "$replace_ack" $replace_index]
                    set ack [lindex [split $ack ":"] 1]
                }
            }

            ## See if the user passed a value to override the ack code.
            set ackcode AA
            set replace_ackcode ""
            keylget uargs ACK_CODE replace_ackcode
            if {[string length $replace_ackcode] != 0} {
                if {[set replace [lsearch -inline $replace_ackcode "$msg_type:*"]] != ""} {
                    set ackcode [lindex [split $replace ":"] 1]
                } elseif {[set replace [lsearch -all -inline $replace_ackcode "\\*:*"]] != ""} {
                    set ackcode [lindex [split $replace ":"] 1]
                }
            }

            # Build the MSH/MSA segment for the reply.
            # Add empty segment for extra return at the end.
            lappend reply_data [join [list MSH $encode $rec_app $rec_fac $snd_app $snd_fac $reply_time $sec $ack $reply_ID $pid $vid] $field_delim]
            lappend reply_data [join [list MSA $ackcode $mcid] $field_delim]
            lappend reply_data ""
            set reply_data [join $reply_data "\r"]

            # Create the reply message
            set rh [msgcreate -type reply $reply_data]

            # Modify the meta data for the reply, to work with multiserver
            # With driverctrl box unchecked this works
            msgmetaset $rh DRIVERCTL [msgmetaget $mh DRIVERCTL]

            # Appropriately return
            lappend dispList "OVER $rh"                             ;# Send reply back
            lappend dispList "CONTINUE $mh"                         ;# Continue the incoming message
        }

        time {
        }

        shutdown {
        }

        default {
            error "Unknown mode '$mode' in tps_Generic_ACK"
        }
    }

    return $dispList
}



