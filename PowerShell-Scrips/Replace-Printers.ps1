<#
.SYNOPSIS
  Name:Replace-Printers.ps1
Replaces existing printers with new printers based on a file

.NOTES
  Updated: 2018-11-12
  Author: Richie
  ToDo:
     Most things     
#>
# Declarations

$ReplacePrintersFile = 'D:\git\WCU-PaperCut\WCU-PaperCut\PowerShell-Scrips\ReplacePrinters.tsv'
$OldServers = "^.*centronics.*$|^.*imagewriter.*$|^.*epson.*$"

# Get a list and create an array of all installed shared printers
$InstalledPrinters = Get-Printer | Where-Object { $_.type -eq "Connection" }
$ReplacePrinters = [Collections.Generic.List[Object]](Import-Csv $ReplacePrintersFile -Delimiter "`t" -Header "OldPrinter","NewPrinter")

foreach ($CurrentPrinter in $InstalledPrinters){
    if ($CurrentPrinter -match $OldServers){
        $index = $ReplacePrinters.FindIndex( {$args[0].OldPrinter -eq $CurrentPrinter.Name} )
        if ($index -ne "-1"){
            Remove-Printer $CurrentPrinter.Name
            Add-Printer -ConnectionName $ReplacePrinters[$index].NewPrinter
        }
    }

}



