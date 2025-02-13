#################################################################################################################
# Name:        tps_FR_EPIC
# Author:      Todd /Megan
# Purpose:     Changes that all Epic *FR* threads will need.
#                   create sending facility from pv1 segment.
#                   code for the odd rooms like 5216/5216.
# UPoC type:   tps
# Args:        tps keyedlist containing the following keys:
#              MODE    run mode ("start", "run" or "time")
#              MSGID   message handle
#              ARGS    user-supplied arguments:
#                   <describe user-supplied args here>
#
# Returns:     tps disposition list:
#              mh is CONTINUEd or KILLed (Original message)
#
# Revisions: 09/09/16 -  - Added code to strip the room and the "-" off of the bed field for field PV1.6
# Revisions: 02/03/2017 -  - Added code to skip facility logic if the message came from  since there is no facility.
#            02/14/2017 -  - Commented out the odd room code since they did not build them with the slash.
#            03/09/2017 -  - Added code to send race in VXU transactions for Immunizations to the State.
#            03/09/2017 -  - Added code to add BBK to MSH.9 for BBK Only Encounters so we can route to Softbank ONLY.
#            04/04/2017 -  - Added a temp proc. to use between the East and West.
#            05/11/2017 -  - Added code to move PID-18.1 to MSH-4 for  only.
#            07/14/2017 -  - Added empty PV1 segment if pv1Index is not found.  The message will be killed since we route of of pv13.
#                                    Modified the *CUSTOM* code and added a proc to call.  There will be another in the future.
#            10/04/2017 -  - Added two new procs and a calling section to call those procs for doctor Ids. Epic can send the Ids in any order.
#            10/12/2017 -  - Commented out the line of code that defaults , so it will send to  before the west go-live.
#            10/18/2017 -  - Changed AH to HSC since AH will never come out, but AHSC will.  We only look at the last 3 and don't want to change that today!
#            11/02/2017 -  - Added code to add ESCR to MSH.9 for Documentation Encounters so we can route to  ONLY.
#            04/09/2018 -  - Added code to change MSH.9 to TELE for transactions with  in the EVN.4 field to only send to  and
proc tps_FR_EPIC { args } {
    keylget args MODE mode                  ;# Fetch mode
    set dispList {}            ;# Nothing to return
    global HciConnName HciSite env

    switch -exact -- $mode {
        start {
        }

        run {
            keylget args MSGID mh
            set data [msgget $mh]                   ;# message data
            set fldDelim [cindex $data 3]        ;# Field delimiter
            set compDelim [cindex $data 4]         ;# Component delimiter
            set repDelim [cindex $data 5]          ;# Repetition delimiter
            set segments [split $data "\r"]          ;# Segments List
            set thread $HciConnName

            #echo ""
            #echo "[lindex [info level 0] 0]'s Data:\r$data"
            #echo ""

            # Send NPI in 1st repetition.
            set segList [list [list PD1 4] [list PV1 7 8 9 17] [list ORC 12] [list OBR 16 32] [list TXA 5 9 10 22]]
            set segments [FR_EPIC_NpiTest $segList $segments]


            # Prod or Test?
            # Temp, used for temp proc FR_EPIC_Site below..
            set host [info hostname]
            if {[regexp {prd} $host]} {
                set clEnv "Prod"
            } else {
                set clEnv "Test"
            }

            # Initialize vars.
            set fac ""
            set kill 0
            set mrnKill 0
            set ordEvent ""
            set host [info hostname]

            #---------------------------------------------- PV1 -------------------------------------------------#
            set pv1Index [lsearch $segments "PV1|*"]
            if {[string equal $pv1Index -1]} {set pv1Seg "PV1|||||||||||||||||||||||||||||||||||||||||||||||||||"}
            set pv1Seg [lindex $segments $pv1Index]
            set pv1Flds [_lextend [split $pv1Seg $fldDelim] 20]

            # Get patient location, room, bed, facility.
            # Facility = last 4 characters of dep 4001.
            set patLoc [string toupper [lindex $pv1Flds 3] ]
            set spPatLoc [_lextend [split $patLoc $compDelim] 4]
            set dept [lindex $spPatLoc 0]
            set room [lindex $spPatLoc 1]
            set bed [lindex $spPatLoc 2]
            set revLoc [lindex $spPatLoc 3]
            set bedLtr [lindex [split $bed "-"] 1]
            set fac [string range [lindex $spPatLoc 3] end-3 end]

            #Get Previous Location in a patient transfer in PV1.6
            set prevLoc [string toupper [lindex $pv1Flds 6] ]
            set spPrevLoc [_lextend [split $prevLoc $compDelim] 4]
            set prevDept [lindex $spPrevLoc 0]
            set prevRoom [lindex $spPrevLoc 1]
            set prevBed [lindex $spPrevLoc 2]
            set prevRevLoc [lindex $spPrevLoc 3]
            set prevBedLtr [lindex [split $prevBed "-"] 1]

            #Get the Pt Class, Service and Financial Class and ensure they are upper case.
            set ptClass [string toupper [lindex $pv1Flds 2] ]
            set service [string toupper [lindex $pv1Flds 10] ]
            set finClass [string toupper [lindex $pv1Flds 20] ]

            # Get the CSN
            set csn [lindex $pv1Flds 19]

            # Replace with new dept, room and letter bed.
            set spPatLoc [lreplace $spPatLoc 2 2 $bedLtr]
            set spPatLoc [lreplace $spPatLoc 1 1 $room]
            set spPatLoc [lreplace $spPatLoc 0 0 $dept]

            #Replace Previous Location with new dept, room and letter bed.
            set spPrevLoc [lreplace $spPrevLoc 2 2 $prevBedLtr]
            set spPrevLoc [lreplace $spPrevLoc 1 1 $prevRoom]
            set spPrevLoc [lreplace $spPrevLoc 0 0 $prevDept]

            #Replace the Pt Class and Service
            set pv1Flds [lreplace $pv1Flds 2 2 $ptClass]
            set pv1Flds [lreplace $pv1Flds 10 10 $service]
            set pv1Flds [lreplace $pv1Flds 20 20 $finClass]

            # Join patient location back.
            set patLoc [join $spPatLoc $compDelim]
            set pv1Flds [lreplace $pv1Flds 3 3 $patLoc]

            #Join previous location back
            set prevLoc [join $spPrevLoc $compDelim]
            set pv1Flds [lreplace $pv1Flds 6 6 $prevLoc]

            # Replace old pv1 with new pv1.
            set pv1Seg [join $pv1Flds $fldDelim]
            set segments [lreplace $segments $pv1Index $pv1Index $pv1Seg]
            #----------------------------------------------- EVN --------------------------------------------------#
            # Get ordEvent.
            set evnIndex [lsearch $segments "EVN|*"]
            if {![string equal $evnIndex -1]} {
                set evnSeg [lindex $segments $evnIndex]
                set evnFlds [split $evnSeg $fldDelim]

                #Grab the event
                set ordEvent [lindex $evnFlds 4]

            }

            #----------------------------------------- set facility (MSH) --------------------------------------------#
            set mshIndex [lsearch $segments "MSH|*"]
            set mshSeg [lindex $segments $mshIndex]
            set mshFlds [split $mshSeg $fldDelim]

            #Get msg type in MSH.9, make sure it is upper case and split by comp delim.
            set msgType [split [string toupper [lindex $mshFlds 8]] $compDelim]
            #Grab the message type in MSH.9.0
            set adtType [lindex $msgType 0]
            set transType [lindex $msgType 1]


            #1. get examples of each of these exceptions from epic
            #2. how to get the spaces in the words to work with the |?
            #   \\x20 maybe with -regexp
            #   \x20 didn't seem to work with -regexp

            switch -exact [string toupper $revLoc] {
                " COMMONS " {
                    set fac ""
                }
                " HEALTH CENTER " {
                    set fac ""
                }
                " ST   " {
                    set fac ""
                }
                "    " {
                    set fac ""
                }
            }

            #grab the transaction type from MSH.9.1
            set mso [string range [lindex $spPatLoc 0] 0 2]
            if {[regexp {^(A28|A31|V04)$} $transType]} {
                set fac ""
            }
            if {[regexp {^(MSO)$} $mso]} {
                set fac "MSO"
            }

            #If Dept is  to send to  and change Event to .  That way it will only route to .
            if {[string equal $dept " ACC CALL"]} {
                # set fac ""
                set ordEvent "CUSTOM_ORD_ENC"
            }
            #Temp code to find  msgs at the time between go lives.
            switch -regexp $fac {
                {
                    set fac ""
                }
                {
                    set fac ""
                }
                {
                    set fac ""
                }
                {
                    set fac ""
                }
                {
                    set fac ""
                }
                {
                    set fac ""
                }
                {
                    set fac ""
                }
                {
                    set fac ""
                }
                {
                    set fac ""
                }
                {
                    set fac ""
                }
                default {
                    set kill 1
                    set subject "Missing DEP 4001\\.2 on $HciConnName thread in the $HciSite site"
                }
            }

            # Set sending facility from Epic's pv1:3.4.
            set mshFlds [lreplace $mshFlds 3 3 $fac]

            #If event is the custom event created for order encounters, change the event type in MSH.9.0.  We ONLY want these to go to  and nowhere else.
            if {[string equal $ordEvent "CUSTOM_ORD_ENC"]} {
                set adtType [FR_EPIC_Enc $adtType ""]
            }



            # Replace msh with new msgType
            set msgType [join [concat $adtType $transType] $compDelim]
            set mshFlds [lreplace $mshFlds 8 8 $msgType]

            # Replace msh segment back into the msg.
            set mshSeg [join $mshFlds $fldDelim]
            set segments [lreplace $segments $mshIndex $mshIndex $mshSeg]

            #---------------------------------------------- PID ---------------------------------------------------#
            set pidIndex [lsearch $segments "PID|*"]
            set pidSeg [lindex $segments $pidIndex]
            #Ensure we have 30 fields in the PID.
            set pidFlds [_lextend [split $pidSeg $fldDelim] 30]

            if {$pidIndex>=0} {

                # Remove patient name id.
                #set ptName [string toupper [lindex $pidFlds 5] ]
                set ptName [join [lreplace [_lextend [split [string toupper [lindex $pidFlds 5]] $compDelim] 7] 6 6 ""] $compDelim]
                set pidFlds [lreplace $pidFlds 5 5 $ptName]

                #Get the race, ethnicity, language, religion and marital status coded fields and ensure they are upper case.
                set race [string toupper [lindex $pidFlds 10] ]
                set ethnicity [string toupper [lindex $pidFlds 22] ]
                set lang [string toupper [lindex $pidFlds 15] ]
                set ms [string toupper [lindex $pidFlds  16] ]
                set rel [string toupper [lindex $pidFlds 17] ]
                set har [lindex $pidFlds 18]

                #Store the HAR in USERDATA in the metadata to send to 3M
                msgmetaset $mh USERDATA $har

                #  does not want the facility in MSH-4.  They want the -specific
                # client identifier, which is in PID-18 on all  order messages.
                if {$thread == "CPALORD_FR_EPIC"} {
                    set clientid [lindex [split [lindex $pidFlds 18] $compDelim] 0]

                    # Set sending facility
                    set mshFlds [lreplace $mshFlds 3 3 $cpalclientid]
                    set mshSeg [join $mshFlds $fldDelim]
                    set segments [lreplace $segments $mshIndex $mshIndex $mshSeg]
                    set kill 0
                }

                #Copy the CSN from PV1.19 to PID.18
                set pidFlds [lreplace $pidFlds 18 18 $csn]

                #Replace the fields with the upper case version
                set pidFlds [lreplace $pidFlds 10 10 $race]
                set pidFlds [lreplace $pidFlds 22 22 $ethnicity]
                set pidFlds [lreplace $pidFlds 15 15 $lang]
                set pidFlds [lreplace $pidFlds 16 16 $ms]
                set pidFlds [lreplace $pidFlds 17 17 $rel]

                #Set the Race and Ethnicity to Blank to downstreams
                #State regs need these values on imms.
                if {![string equal $msgType "VXU^V04"]} {
                    set blank ""
                    set pidFlds [lreplace $pidFlds 10 10 $blank]
                    set pidFlds [lreplace $pidFlds 22 22 $blank]
                }

                # get the  number
                set mrnList [lindex $pidFlds 3]
                if {![regexp {} $mrnList]} {
                    set kill 1
                    set mrnKill 1
                    set subject "Missing  on $HciConnName thread in the $HciSite site"
                }

                set subMrnList [split $mrnList $repDelim]
                set index 0
                foreach mrnList $subMrnList {
                    set newMrnList [split $mrnList $compDelim]
                    # Ensure we have 4 fields in the list
                    _lextend "newMrnList" 4
                    set subMrnfld [lindex $newMrnList 4]

                    #Grab the WSH MRN from the list and move it.
                    if {[string equal $subMrnfld ""]} {
                        set subMrnList [lreplace $subMrnList $index $index]
                        set subMrnList [linsert $subMrnList 0 $mrnList]

                        #Join it back together with the repDelim.
                        set subMrnList [join $subMrnList $repDelim]
                        set pidFlds [lreplace $pidFlds 3 3 $subMrnList]
                    }
                    incr index
                }

                # get the name fields
                set name [lindex $pidFlds 5]
                set spName [split $name $compDelim]
                set lname [lindex $spName 0]

                # skip transactions with lastname ZZTEST or
                if {[string equal $lname "ZZTEST"]} {
                    lappend dispList "KILL $mh"
                    return $dispList
                }

                #Replace pid segment back into the message.
                set pidSeg [join $pidFlds $fldDelim]
                set segments [lreplace $segments $pidIndex $pidIndex $pidSeg]
            }



            #---------------------------------------------- KILL ---------------------------------------------------#
            #skipped facility logic and sending ALL facilities to Lexmark if it's an ADT transaction and there is an MRN in PID.3
            if {[string equal $kill "1"]} {
                if {[regexp {ADT} $adtType] && [string equal $mrnKill "0"]} {
                    # Join the HL7 msg together.
                    set data [join $segments "\r"]

                    # Continue the modified message
                    msgset $mh $data

                    # Make a copy of modified message handle.
                    set cpMh [msgcopy $mh]
                    msgmetaset $cpMh DESTCONN
                    lappend dispList "SEND $cpMh"
                }
                set to [join [list "@.org" "@.org" "@.org"] ","]
                lappend body "$data"
                _Email [dict create \
                    to $to \
                    from "@.org" \
                    subject $subject \
                    body [list \
                        [dict create content [join $body "\r\n"]] \
                        [dict create content "<b>[join $body "<br/>"]</b>" type "text/html"] \
                    ]
                ]
                lappend dispList "KILL $mh"
                return $dispList
            }

            # Join the HL7 msg together.
            set data [join $segments "\r"]

            # Continue the modified message
            msgset $mh $data
            lappend dispList "CONTINUE $mh"

        }
    }
    return $dispList
}



######################################################################
######################################################################
# Name:        tps_MERGE_FR_EPIC
# Author:      Megan
# Purpose:     Add facility to the Merge(A40) transactions from Epic
# UPoC type:   tps
# Args:        tps keyedlist containing the following keys:
#              MODE    run mode ("start", "run" or "time")
#              MSGID   message handle
#              ARGS    user-supplied arguments:
#                   <describe user-supplied args here>
#
# Returns:     tps disposition list:
#              mh is CONTINUEd or KILLed (Original message)
#
# Revisions:
#

proc tps_MERGE_FR_EPIC { args } {
    keylget args MODE mode                  ;# Fetch mode
    set dispList {}            ;# Nothing to return
    global HciConnName HciSite env

    switch -exact -- $mode {
        start {
        }

        run {
            keylget args MSGID mh
            set data [msgget $mh]                   ;# message data
            set fldDelim [cindex $data 3]        ;# Field delimiter
            set compDelim [cindex $data 4]         ;# Component delimiter
            set repDelim [cindex $data 5]          ;# Repetition delimiter
            set segments [split $data "\r"]          ;# Segments List

            set segMsh [lindex $segments 0]          ;# MSH segment, always index 0
            set fldList [split $segMsh $fldDelim]

            #Get msg type in MSH.9, make sure it is upper case and split by comp delim.
            set msgType [split [string toupper [lindex $fldList 8]] $compDelim]    ;# Msg type, index 8

            #grab the transaction type from MSH.9.1
            set transType [lindex $msgType 1]
            #echo "transType:$transType"

            #--------------------------------------------- MERGE ----------------------------------------------------#

            set mrgIndex [lsearch $segments "MRG|*"]
            set mrgSeg [lindex $segments $mrgIndex]
            set mrgFlds [split $mrgSeg $fldDelim]
            #echo "MRGIndex: $mrgIndex"
            #echo "MRGSeg: $mrgSeg"
            if {![string equal $mrgIndex "-1"]} {
                set mrnList [lindex $mrgFlds 1]
                set subMrnList [split $mrnList $repDelim]
                set index 0
                foreach mrnList $subMrnList {
                    set newMrnList [split $mrnList $compDelim]
                    # Ensure we have 4 fields in the list
                    _lextend "newMrnList" 4
                    set subMrnfld [lindex $newMrnList 4]

                    #Grab the WSH MRN from the list and move it.
                    if {[string equal $subMrnfld ""]} {
                        set subMrnList [lreplace $subMrnList $index $index]
                        set subMrnList [linsert $subMrnList 0 $mrnList]

                        #Join it back together with the repDelim.
                        set subMrnList [join $subMrnList $repDelim]
                        set mrgFlds [lreplace $mrgFlds 1 1 $subMrnList]
                    }
                    #echo "mrgFlds:$mrgFlds"
                    incr index
                }
                #Join the message back together
                set mrgSeg [join $mrgFlds $fldDelim]
                #echo "mrgSeg:$mrgSeg"
                set segments [lreplace $segments $mrgIndex $mrgIndex $mrgSeg]
                #foreach seg $segments {
                #   echo $seg
                # }
                # Join the HL7 msg together.
                set data [join $segments "\r"]

                # Continue the modified message
                msgset $mh $data
            }

            #A40 has no facility, take the A40 message and make a copy for each facility and kill the original message
            if {[string equal $transType "A40"]} {
                #make a YH copy of the original message
                set mhCopyYH [msgcopy $mh]
                #echo "mhCopyYH: $mhCopyYH"
                set dataYH [msgget $mhCopyYH]
                #split already modified message into segments
                set YHsegList [split $dataYH "\r"]
                #echo "YHSegList:$YHsegList"
                #Find the PID segment
                set pidIndex [lsearch $YHsegList "PID|*"]
                #Insert the PV1 segment with facility after the PID segment
                set YHSegList [linsert $YHsegList [expr $pidIndex + 1] "PV1|||^^^  "]
                #echo "New Seg List:$YHSegList"

                # Join the HL7 msg together.
                set dataYH [join $YHSegList "\r"]

                # Continue the modified message
                msgset $mhCopyYH $dataYH
                lappend dispList "CONTINUE $mhCopyYH"


                #make a GH copy of the original message
                set mhCopyGH [msgcopy $mh]
                #echo "mhCopyGH: $mhCopyGH"
                set dataGH [msgget $mhCopyGH]
                #split already modified message into segments
                set GHsegList [split $dataGH "\r"]
                #echo "GHSegList:$GHsegList"
                #Find the PID segment
                set pidIndex [lsearch $GHsegList "PID|*"]
                #Insert the PV1 segment with facility after the PID segment
                set GHSegList [linsert $GHsegList [expr $pidIndex + 1] "PV1|||^^^  "]
                #echo "New Seg List:$GHSegList"

                # Join the HL7 msg together.
                set dataGH [join $GHSegList "\r"]

                # Continue the modified message
                msgset $mhCopyGH $dataGH
                lappend dispList "CONTINUE $mhCopyGH"

                #make an RH copy of the original message
                set mhCopyRH [msgcopy $mh]
                #echo "mhCopyRH: $mhCopyRH"
                set dataRH [msgget $mhCopyRH]
                #split already modified message into segments
                set RHsegList [split $dataRH "\r"]
                #echo "RHSegList:$RHsegList"
                #Find the PID segment
                set pidIndex [lsearch $RHsegList "PID|*"]
                #Insert the PV1 segment with facility after the PID segment
                set RHSegList [linsert $RHsegList [expr $pidIndex + 1] "PV1|||^^^"]
                #echo "New Seg List:$RHSegList"

                # Join the HL7 msg together.
                set dataRH [join $RHSegList "\r"]

                # Continue the modified message
                msgset $mhCopyRH $dataRH
                lappend dispList "CONTINUE $mhCopyRH"

                #make an EH copy of the original message
                set mhCopyEH [msgcopy $mh]
                #echo "mhCopyEH: $mhCopyEH"
                set dataEH [msgget $mhCopyEH]
                #split already modified message into segments
                set EHsegList [split $dataEH "\r"]
                #echo "EHSegList:$EHsegList"
                #Find the PID segment
                set pidIndex [lsearch $EHsegList "PID|*"]
                #Insert the PV1 segment with facility after the PID segment
                set EHSegList [linsert $EHsegList [expr $pidIndex + 1] "PV1|||^^^"]
                #echo "New Seg List:$EHSegList"

                # Join the HL7 msg together.
                set dataEH [join $EHSegList "\r"]

                # Continue the modified message
                msgset $mhCopyEH $dataEH
                lappend dispList "CONTINUE $mhCopyEH"

                #make a GS copy of the original message
                set mhCopyGS [msgcopy $mh]
                #echo "mhCopyGS: $mhCopyGS"
                set dataGS [msgget $mhCopyGS]
                #split already modified message into segments
                set GSsegList [split $dataGS "\r"]
                #echo "GSSegList:$GSsegList"
                #Find the PID segment
                set pidIndex [lsearch $GSsegList "PID|*"]
                #Insert the PV1 segment with facility after the PID segment
                set GSSegList [linsert $GSsegList [expr $pidIndex + 1] "PV1|||^^^"]
                #echo "New Seg List:$GSSegList"

                # Join the HL7 msg together.
                set dataGS [join $GSSegList "\r"]

                # Continue the modified message
                msgset $mhCopyGS $dataGS
                lappend dispList "CONTINUE $mhCopyGS"

                msgset $mh $data
                lappend dispList "KILL $mh"
            } else {
                msgset $mh $data
                lappend dispList "CONTINUE $mh"
            }
        }
    }
    return $dispList
}



######################################################################
######################################################################
# Name:        trxid_FR_EPIC
# Author:      Megan
# Purpose:     create trxID based on hospital to determine routing
# UPoC type:   trxid
# Args:     msgId = message handle
#           args  = (optional) user arguments
# Returns:  The message's transaction ID
#
# Notes:
#    The message is both modify- and destroy-locked -- attempts to modify
#    or destroy it will error out.
#

proc trxid_FR_EPIC { mh {args {}} } {
    set trxId trxid              ;# determine the trxid
    set msg [msgget $mh]                   ;# msg data
    set fieldDelim [string index $msg 3]        ;# Field delimiter
    set compDelim [string index $msg 4]         ;# Component delimiter
    set segList [split $msg "\r"]          ;# Segments List
    set segMSH [lindex $segList 0]          ;# MSH segment, always index 0
    set fldList [split $segMSH $fieldDelim]        ;# MSH Field List
    set sendFac [string toupper [lindex $fldList 3]]    ;# Msg type, index 3.  Valued by tps_FR_EPIC proc.

    #Get msg type in MSH.9, make sure it is upper case and split by comp delim.
    set msgtype [split [string toupper [lindex $fldList 8]] $compDelim]    ;# Msg type, index 8

    #grab the first piece of the msg type.
    set eventType [lindex $msgtype 0]
    set spacer "_"

    # determine the trxid
    set trxId $sendFac$spacer$eventType
    return $trxId                ;# return it
}

proc FR_EPIC_Enc {adtType suffix} {
    set adtType [join [concat $adtType $suffix] ""]
    return $adtType
}

proc FR_EPIC_Npi { doc } {
    if {[regexp {~} $doc]} {
        set docSp [split $doc "~"]
        set npiIndex [lsearch $docSp "*\^NPI\^*"]
        if {![string equal $npiIndex "0"]} {
            set docSp [linsert $docSp 0 [lindex $docSp $npiIndex]]
            set docSp [lreplace $docSp [expr $npiIndex + 1] [expr $npiIndex + 1] ""]
        }
        set doc [join $docSp "~"]
    }
    return $doc
}

# segList is the segment and doctor fields, E.g.[list PD1 4] [list PV1 7 8 9 17] [list ORC 12] [list OBR 16 32]
# segments is the whole hl7 message.
proc FR_EPIC_NpiTest { segList segments } {
    foreach item $segList {
        set index [lsearch $segments [lindex [split $item \x20] 0]|*]        ;# search for the segment from segList, like OBR|*.
        if {$index>=0} {                                                     ;# if segment found in the hl7 msg, continure.
        set seg [lindex $segments $index]                                 ;# the segment, like OBR.
        set flds [_lextend [split $seg "|"] 40]                            ;# the segment flds, like OBR1, OBR2, OBR3, etc...
        set docFlds [lrange [split $item \x20] 1 end]                     ;# the doctor fields that were sent into this proc from the calling proc above.
        foreach docId $docFlds {
            set newDoc [FR_EPIC_Npi [lindex $flds $docId]]
            set newFlds [lreplace $flds $docId $docId [FR_EPIC_Npi [lindex $flds $docId]]]
            set newSeg [join $newFlds "|"]
            set segments [lreplace $segments $index $index $newSeg]
            set flds $newFlds
            #           set segments [lreplace $segments $index $index [join [lreplace $flds $docId $docId [FR_EPIC_Npi [lindex $flds $docId]]] "|"]]
        }
    }
}
return $segments
}