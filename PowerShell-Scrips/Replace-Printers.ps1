<#
.SYNOPSIS
  Name:Replace-Printers.ps1
Replaces existing printers with new printers based on a file

.NOTES
  Updated: 2018-11-13
  Author: Richie
  ToDo:
     Make Compatable with win7 by using WMI instead of get-printer  
#>
# Declarations

$ReplacePrintersFile = '\\printserver.wcu.edu\Share\Lists\ReplacePrinterList.tsv'
$OldServers = "^.*centronics.*$|^.*imagewriter.*$|^.*epson.*$"

# Get a list and create an array of all installed shared printers
$InstalledPrinters = Get-WmiObject -Class Win32_Printer
$ReplacePrinters = [Collections.Generic.List[Object]](Import-Csv $ReplacePrintersFile -Delimiter "`t" -Header "OldPrinter","NewPrinter")

foreach ($CurrentPrinter in $InstalledPrinters){
    if ($CurrentPrinter -match $OldServers){
        $index = $ReplacePrinters.FindIndex( {$args[0].OldPrinter -eq $CurrentPrinter.Name} )
        if ($index -ne "-1"){
            (New-Object -ComObject WScript.Network).RemovePrinterConnection($CurrentPrinter.Name)
            (New-Object -ComObject WScript.Network).AddWindowsPrinterConnection($ReplacePrinters[$index].NewPrinter)
        }
    }

}



