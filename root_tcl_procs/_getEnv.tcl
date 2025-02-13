if 0 {
    Name:
        _getEnv
    
    Arguments:
        host - Sends the host server name.  
    About:
        If you need to know what server the code is running on, for email code example.  In my email code i like to send what server sent it. Prod is more important
        than tst or poc.  
    History:
        2017-06-14 tyingl01
            -initial version
}
proc _getEnv {host} {      
   set host [string tolower $host] 
   if {[regexp {prd} $host]} {
      set env "PROD"
   } elseif {[regexp {tst} $host]} {
      set env "TST"
   } elseif {[regexp {poc} $host]} {
      set env "POC"
   } else {
      set env "$host"
   }
   return $env
}

