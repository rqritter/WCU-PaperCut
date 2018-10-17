<#
.SYNOPSIS
  Name:Get-UserDefferences.ps1
  Compares new extract file from banner (delivered daily to Bounty2 at 6AM & copied to papercut server at 6:15AM)
  to a report file (created by papercut daily around 1AM). Produces a tsv file with accounts that need to be updated.
  File should be consumed by "Update-CardNumbers.ps1"

.NOTES
  Updated: 2018-10-01
  ToDo:
    1. Exempt a list of accounts when making $cardNumNew

#>

#----------------[ Declarations ]------------------------------------------------------
$formatedDate = get-date -f yyyy-MM-dd
$startTime = get-date

$newCSV = "C:\Scripts\papercut-extract.tsv"
$oldCSV = "C:\Program Files\PaperCut MF\server\data\scheduled-reports\current_users.csv"
$unManagedFile = "C:\Scripts\UnManagedUsers.tsv"
$resultsFile = "C:\Scripts\results.tsv"
$missingFile = "C:\Scripts\missing_users.tsv"
$logFile = "c:\scripts\logs\UserDifferences-$formatedDate.log"

$unManagedUsers = Get-Content $unManagedFile | Select-Object -Skip 2 | ConvertFrom-Csv
$cardNumNew = Import-Csv $newCSV -Delimiter "`t" -Header Username,"Primary Card Number",PIN,"Secondary Card Number"
$cardNumOld = Get-Content $oldCSV | Select-Object -Skip 2 | ConvertFrom-Csv

#----------------[ Main Execution ]----------------------------------------------------
# Backup current results, missing files
Move-Item -Path $resultsFile -Destination "$resultsFile.bak" -Force
Move-Item -Path $missingFile  -Destination "$missingFile.bak" -Force

# Compare records in the two files (Can't find a better way to do this)
foreach ($newRecord in $cardNumNew)
{
# Skip unmanaged users
if ($unManagedUsers.username -notcontains $newRecord.Username)
   {
   # Find users not in Papercut
   if ($cardNumOld.username -notcontains $newRecord.Username)
      {
      $missing = "$($newRecord.username)`t$($newRecord."Primary Card Number")`t-`t$($newRecord."Secondary Card Number")"
      Out-File -FilePath $missingFile -InputObject $missing -Append
      }

   # Find users with non-matching card numbers
   foreach ($oldRecord in $cardNumOld)
      {
      if ($newRecord.username -eq $oldRecord.username)
         {
         if (($newRecord."Primary Card Number" -ne "-") -and ($newRecord."Primary Card Number" -ne $oldRecord."Primary Card Number"))
            {
            $conflicts = "$($newRecord.username)`t$($newRecord."Primary Card Number")`t-`t$($newRecord."Secondary Card Number")"
            Out-File -FilePath $resultsFile -InputObject $conflicts -Append
            }
         elseif (($newRecord."Secondary Card Number" -ne "-") -and ($newRecord."Secondary Card Number" -ne $oldRecord."Secondary Card Number"))
            {
            $conflicts = "$($newRecord.username)`t$($newRecord."Primary Card Number")`t-`t$($newRecord."Secondary Card Number")"
            Out-File -FilePath $resultsFile -InputObject $conflicts -Append
            }
         }
      }
   }
}
