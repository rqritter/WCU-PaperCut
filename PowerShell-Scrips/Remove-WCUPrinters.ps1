# Removes printers added from printservec.wcu.edu
get-printer | where {$_.ComputerName -eq "printserver.wcu.edu"} | remove-printer