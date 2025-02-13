if 0 {
    Name::      _Email
    Author::    Todd Horst
    Version::   .2

    About:
    Uses smtp server to send email.

    *Capable of sending to external email clients.
    *Handles attachments (and if the attachment file doesnt actually exist)
    *Handles from, cc, and bcc
    *Handles multipart emails (html or text or any valid document type)
    *Could point to a different smtp server
    *Can output debug information
    *Can send outlook meeting invites

    Param List:
    settings is a dictionary with the below entries

    Settings Dict:
    FIELD       TYPE            DEFAULT                 DESCRIPTION
    Required:
    to          string|list     -                       A comma seperated string of email addresses, can also take a list that can be automatically joined for you

    Not Required:
    body          list of dict    ""                      A list of dictionaries
    content   string          ""                      The content that should be placed in the body
    type      string          ""                      The type of format of the content
    server        string          "smtp..org"     The smtp server to use
    from          string          "noreply@.org"  The email will show from
    cc            string|list     ""                      A comma seperated string of email addresses, can also take a list that can be automatically joined for you
    bcc           string|list     ""                      A comma seperated string of email addresses, can also take a list that can be automatically joined for you
    subject       string          ""                      Subject for email
    type          string          "text/plain"            Type for body
    debug         int             0 (0-False, 1-True)     Determines whether addition output is rendered
    attachments   list of dict    ""                      A list of dictionaries
    path      string          ""                      If the attachment is a physical file, give the path
    name      string          Filename|attach$index   If you want to override the name, if path given, defaults to filename, if string defaults to attach###
    type      string          "application/text"      The type of format of the attachment
    content   string          ""                      If the attachment isnt a physical file, give its contents
    throwerror    bool            true                    If email fails after retryattempts times, throw tcl Error
    retryattempts int             3                       Try this many times

    Known Possible Types:
    http://www.w3.org/TR/html4/types.html (6.7)
    http://www.iana.org/assignments/media-types/index.html

    text/plain
    text/html
    multipart/mixed
    multipart/alternative
    image/gif
    image/jpg
    application/text
    application/octet
    text/calendar; method=REQUEST 	(inline request)
    text/calendar 					(.ics attachment)

    Returns:
    1

    Helpful Websites:
    smtp
    http://tcllib.sourceforge.net/doc/smtp.html
    http://wiki.tcl.tk/1256
    http://www.packtpub.com/article/tcl-handling-email (AWSOME LINK)

    mime
    http://tcllib.sourceforge.net/doc/mime.html
    http://core.tcl.tk/tcllib/doc/trunk/embedded/www/tcllib/files/modules/mime/mime.html
    http://wiki.tcl.tk/779
    http://tcllib.sourceforge.net/doc/mime-README.html

    attachments
    http://code.activestate.com/recipes/65434-sending-mail-with-attachments/
    http://wiki.tcl.tk/3016

    multiple pieces
    http://www.coderanch.com/t/503380/java/java/Java-Mail-text-html-attachment
    http://stackoverflow.com/questions/17097806/send-email-via-smtp-with-attachment-plain-text-and-text-hml
    https://www.packtpub.com/books/content/tcl-handling-email  (AWSOME LINK)

    vcalander
    https://djangosnippets.org/snippets/2215/
    http://www.tutorialsbag.com/2013/06/how-to-create-ical-files-to-work-on.html
    http://core.tcl.tk/tcllib/doc/trunk/embedded/www/tcllib/files/modules/base64/base64.html
    http://stackoverflow.com/questions/29571841/outlook-2013-invite-not-showing-embeded-attachment-text-calendarmethod-reques/29572173#29572173

    uuid
    http://core.tcl.tk/tcllib/doc/trunk/embedded/www/tcllib/files/modules/uuid/uuid.html


    Visual Diagram of Message
    +-----------------------------------------------+
    | multipart/related                             |
    | +---------------------------+  +------------+ |
    | |multipart/alternative      |  | image/gif  | |
    | | +-----------+ +---------+ |  |            | |
    | | |text/plain | |text/html| |  |            | |
    | | +-----------+ +---------+ |  |            | |
    | +---------------------------+  +------------+ |
    +-----------------------------------------------+

    Treeview Diagram of Message
    multipart/mixed
    multipart/alternative (holding the two forms of the body part)
    text/plain
    text/html
    text/plain (attachment #1)
    image/gif (attachment #2)

    TODO:
    2. Encoding (special characters) - WHATS THE SCENARIO?


    Change Log:
    2012/12/06 - Todd Horst
    -Initial Version
    2015/04/08 - Todd Horst
    -Overhaul using dictionary instead of array and simplicity
    -Rename _Email
    -Flesh out multipart so you can now send html and text at same time, not just attachments
    with one body
    -Example of appointment request with attachments
    -Allow string attachments
    -Allow lists for any email (to,cc,bcc)
    -Better handling for empty body
    2017/07/17 - Steve
    -Added throwerror and retryattempts parameters for handling issues with email
    2017/12/11 - Todd Horst
    -Added sendSecure parameter
    -Moved examples to fiddle
    2018/05/01 - Steve
    -Fixed bug with throwerror parameter

    Examples and test cases:

}



proc _Email { settings } {
    package require mime                                                        ;#Get needed packages
    package require smtp

    #Verify required settings are there
    if {![dict exists $settings to]} {
        echo "Mail Error:: Need to define at least 'to' in settings."
        return false
    }

    #Same as jQuery, have defaults object merged with param
    set settings [dict merge [dict create \
        body "" \
        server "smtp..org" \
        from "noreply@.org" \
        cc "" \
        bcc "" \
        type "text/plain" \
        subject "" \
        debug 0 \
        attachments "" \
        other "" \
        throwerror true \
        retryattempts 3 \
        sendsecurely false \
        ] $settings]

    # Send securely?
    if {[dict get $settings sendsecurely] && ![string match -nocase "secure:*" [dict get $settings subject]]} {
        dict set settings subject "Secure: [dict get $settings subject]"
    }

    #auto join to for them
    if {[llength [dict get $settings to]]>1} {
        dict set settings to [join [dict get $settings to] ","]
    }
    #auto join cc for them
    if {[llength [dict get $settings cc]]>1} {
        dict set settings cc [join [dict get $settings cc] ","]
    }
    #auto join bcc for them
    if {[llength [dict get $settings bcc]]>1} {
        dict set settings bcc [join [dict get $settings bcc] ","]
    }

    #Setup Mail Parts
    set MailParts ""
    foreach b [dict get $settings body] {

        #If they didnt pass a type with the body, default to global default
        if {![dict exists $b type]} {dict set b type [dict get $settings type]}

        #Add body to message
        lappend MailParts [mime::initialize -canonical [dict get $b "type"] -string [dict get $b "content"] -param {charset "utf-8"} -encoding 8bit]
    }


    #Loop over attachments
    set attParts ""
    set i 0
    foreach att [dict get $settings attachments] {
        incr i

        #Ensure there is a type
        if {![dict exists $att type]} { dict set att type "octet-stream" }

        #File based attachments
        if {[dict exists $att path] && [file exists [dict get $att path]]} {

            #Ensure there is a filename
            if {![dict exists $att name]} { dict set att name [file tail [dict get $att path]] }

            lappend attParts [mime::initialize -canonical "[dict get $att type]; name=\"[dict get $att name]\"" -file [dict get $att path] -header [list Content-Disposition "attachment"]]

            continue
        }

        #String based attachments
        if {[dict exists $att content]} {

            #Ensure there is a filename
            if {![dict exists $att name]} { dict set att name "attach$i"] }

            lappend attParts [mime::initialize \
                -canonical "[dict get $att type]; name=\"[dict get $att name]\"" \
                -string [dict get $att content] \
            ]

        continue
    }
}


# create a container for attachments and a container for mail parts
set mimeMail [mime::initialize -canonical multipart/alternative -parts $MailParts]

set sumMime ""
if {$MailParts!=""} {
    lappend sumMime $mimeMail
}
if {$attParts!=""} {
    set sumMime [concat $sumMime $attParts]
}


#If they dont add any bodies send an empty one
if {$sumMime==""} {
    lappend sumMime [mime::initialize -canonical "text/plain" -string ""]
}

#The sum total of all are pieces
set mimeTotal [mime::initialize -canonical multipart/mixed -parts $sumMime]

#set subject, should there be one
if {[dict get $settings subject] != ""} {
    ::mime::setheader $mimeTotal Subject [dict get $settings subject]
}

#If they want to debug, output the mime package
if {[dict get $settings debug]} {
    echo [::mime::buildmessage $mimeTotal]
}

#Send email.  Tries three times.  If it fails the third time, throw an exception
for {set emailTry 1} {$emailTry <= [dict get $settings retryattempts]} {incr emailTry} {
    catch {
        smtp::sendmessage $mimeTotal \
            -servers [dict get $settings server] \
            -header [list From [dict get $settings from]] \
            -header [list To [dict get $settings to]] \
            -header [list Cc [dict get $settings cc]] \
            -header [list Bcc [dict get $settings bcc]] \
            -debug [dict get $settings debug]
        } catch_return
        if {$catch_return == ""} {
            break
        }
        if {$emailTry == [dict get $settings retryattempts] && [dict get $settings throwerror]} {
            error "Email procedure failed after [dict get $settings retryattempts] tries."
        }
    }

    #Destroy MIME part
    mime::finalize $mimeTotal

    return 1
}