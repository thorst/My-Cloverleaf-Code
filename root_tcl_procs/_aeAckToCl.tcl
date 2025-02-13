if 0 {
    Name:
    _aeAckToCl

    Arguments:  args

    About:
    I use this on *TO* threads, Outbound Tab, Inbound Replies, TPS Inbound Reply UPOC.
    Synapse sends back AE ACKs, but we didn't know about them b/c hcitpsmsgkill just killed the message.
    This proc evaluates each ACK from the receiving system that thread is connected to.
    Note, you need to add user arguments FROM and TO email addresses in the "edit" part of this proc in the stack.
    {FROM } {TO {  }}
    Researching Cl help, I found OBMSGID key, which holds reserved OB messages, is introduced into TPS in RUN mode.
    I may need a catch on the OBMSGID code just to be sure.

    History:
    2018-04-16
    -initial version
}
proc _aeAckToCl { args } {
    keylget args MODE mode
    set dispList {}
    global HciConnName

    switch -exact -- $mode {

        run {

            # get user arguments.
            keylget args ARGS uargs
            keylget uargs FROM from
            keylget uargs TO to

            # get reply ack message.
            keylget args MSGID mh
            set data [msgget $mh]


            # set vars.
            set mail "@.org"
            set env "non-prod"
            set proc [lindex [info level 0] 0]
            set host [info hostname]
            if {[regexp {prd} $host]} {set env "prd"}

            # if to or from var is not set, bad configuration on netConfig.
            # continue on stack, which should be hcitpsmsgkill.
            if {![info exists to] || ![info exists from]} {
                echo "$proc on $HciConnName is not configured correctly"
                lappend dispList "CONTINUE $mh"
                return $dispList
            }

            # get the original message.
            keylget args OBMSGID ob_mh
            set obData [msgget $ob_mh]

            # get to emails.
            foreach x $to {
                lappend newTo $x$mail
            }
            set to [join $newTo ","]

            # if not AA ack, send email.
            if {![regexp {MSA\|AA} $data]} {
                lappend body "Message:" $data \r $obData
                _Email [dict create \
                    to $to \
                    from $from$mail \
                    subject "AE from $HciConnName - $proc ($env)." \
                    body [list \
                        [dict create content "<b>[join $body "<br/>"]</b>" type "text/html"] \
                    ]
                ]
            }

            # Continue msgs to be killed.
            # hcitpsmsgkill is used on incoming replies.
            msgset $mh $data
            lappend dispList "CONTINUE $mh"
        }
    }
    return $dispList
}

