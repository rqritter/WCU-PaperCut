<#
.SYNOPSIS
  Name:Replace-Printers.ps1
  Replaces existing printers with new printers based on a file

.NOTES
  Updated: 2018-11-19
  Author: Richie
  ToDo:
     1. currently the ReplacePrinterList.tsv needs to contain FQDN and short name for printers. Update script so 
        we can enter just one line per printer.
#>
# Declarations

$ReplacePrintersFile = "\\printserver.wcu.edu\Share\Lists\ReplacePrinterList.tsv"
#$ReplacePrintersFile = "D:\git\WCU-PaperCut\WCU-PaperCut\PowerShell-Scrips\ReplacePrinterList.tsv"
$OldServers = "^.*centronics.*$|^.*imagewriter.*$|^.*epson.*$"
$NewServer = "printserver.wcu.edu"

# Get a list and create an array of all installed shared printers
$InstalledPrinters = Get-WmiObject -Class Win32_Printer | Where-Object { $_.SystemName -match "\\\\" }
$ReplacePrinters = [Collections.Generic.List[Object]](Import-Csv $ReplacePrintersFile -Delimiter "`t")

foreach ($Printer in $InstalledPrinters){
    # Check if printer is on one of the old servers
    if ($Printer.SystemName -match $OldServers){
    
        # Attempt to find index of printer in collection
        $index = $ReplacePrinters.FindIndex( {$args[0].OldPrinter -eq $Printer.ShareName} )

        # If index is "-1", printer was not found in collection. Otherwise, replace printer
        if ($index -ne "-1"){

            (New-Object -ComObject WScript.Network).RemovePrinterConnection($Printer.Name)
            (New-Object -ComObject WScript.Network).AddWindowsPrinterConnection("\\printserver.wcu.edu\$($ReplacePrinters[$index].NewPrinter)")
        }
    }
}



