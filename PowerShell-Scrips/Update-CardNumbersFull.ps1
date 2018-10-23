<#
.SYNOPSIS
  Name:Update-CardNumbersFull.ps1
  Script should be run as account papercut.svc@wcu.edu.
  It is needed because the Papercut import will fail and stop importing when it hits a user with a non-unique card number.
  This script has multiple parts, details can be found under each section

  1. Get Updated File: Download the latest export file for users and card numbers

  2. Get User Differences: Compare papercut-export.tsv to a daily papercut user report
     to determine what user cards need to be updated, generating "c:\scripts\results.tsv"

  3. Update Card Numbers: Update papercut using "results.tsv", capturing non-unique card errors
     and dealing with them

.NOTES
  Updated: 2018-10-17
  Author: Richie
  Changes:
    2018-10-17 Adding script to check if active node

  ToDo:
    1. Cleanup the duplication
    2. Consolidate logging
    3. Only run if PaperCut service is running (to check if server is active in the cluster)
#>
#----------------[ Logging TBD ]----------------------------------------------------

# $formatedDate = get-date -f yyyy-MM-dd
# $logFile = "c:\scripts\logs\CardNumbersFull-$formatedDate.log"

#----------------[ Only run if active server ]--------------------------------------
<#
  The PaperCut application server runs on a MS Failover Cluster. This script should only run 
  on the server that is the active node of the cluster. The PaperCut service will only be running on
  the active server so we check the status of the service to see if the script should run.
#>
$pcServiceDisplayName = "PaperCut Application Server"
$pcService = Get-Service -Name $pcServiceDisplayName

if ($pcService.Status -eq "Running")
{

#----------------[ 1. Get Updated File ]--------------------------------------------
<#
Standalone script: Get-UpdatedFile.ps1
  Backup the local "papercut-extract.tsv" file and get the latest extract file from \\Bounty2\nfsprod\dataoutput\it\
  File is tab separated and contains Username, PrimaryCard, PIN, SecondaryCard for active users in Banner
  It is generated daily at 6AM and was setup by Henson Sturgill
#>
#----------------[ Get Updated File - Declarations ]----------------------------------------------------

$currentImportFile = "C:\Scripts\papercut-extract.tsv"
$sourceBounty2 = "\\bounty2\nfsprod\dataoutput\it\"
$newImportFile = "papercut-extract.tsv"

#----------------[ Get Updated File - Main Execution ]--------------------------------------------------

# Backup current file
Copy-Item -Path $currentImportFile -Destination "$currentImportFile.bak" -force

# Map Bounty2
New-PSDrive -Name source -PSProvider FileSystem -Root $sourceBounty2

# Get new file from Bounty2
Copy-Item -Path "source:\$NewImportFile" $CurrentImportFile -Force

# Un-map Bounty2
Remove-PSDrive source

#----------------[ 2. Get User Differences ]----------------------------------------
<#
Standalone script: Get-UserDifferences.ps1
  Compares new extract file from banner (delivered daily to Bounty2 at 6AM & copied to papercut server at 6:15AM)
  to a report file (created by papercut daily around 1AM). Produces a tsv file with accounts that need to be updated.
#>
#----------------[ Get User Differences - Declarations ]------------------------------------------------

$newCSV = "C:\Scripts\papercut-extract.tsv"
$oldCSV = "C:\Program Files\PaperCut MF\server\data\scheduled-reports\current_users.csv"
$unManagedFile = "C:\Scripts\UnManagedUsers.tsv"
$resultsFile = "C:\Scripts\results.tsv"
$missingFile = "C:\Scripts\missing_users.tsv"

$unManagedUsers = Get-Content $unManagedFile | Select-Object -Skip 2 | ConvertFrom-Csv
$cardNumNew = Import-Csv $newCSV -Delimiter "`t" -Header Username,"Primary Card Number",PIN,"Secondary Card Number"
$cardNumOld = Get-Content $oldCSV | Select-Object -Skip 2 | ConvertFrom-Csv

#----------------[ Get User Differences - Execution ]---------------------------------------------------

# Backup current results and missing files
Move-Item -Path $resultsFile -Destination "$resultsFile.bak" -Force
Move-Item -Path $missingFile -Destination "$missingFile.bak" -Force

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

#----------------[ 3. Update Card Numbers ]-----------------------------------------
<#
Standalone script: Update-CardNumbers.ps1
  This script will parse a tab separated file for users with primary card numbers(92#) and secondary card numbers (prox ID).
  The script is not very efficient (i.e. it is slow), so we are running "Get-UserDefferences.ps1" to create the import file.
  It will compare to existing numbers in PaperCut and update if different. If an error is encountered while updating, it will be logged.
  Card number not unique errors can be caused if a user has moved from staff to student or student to staff since their previous primary account will be assigned the card number.
  If the error is caused because a card number not unique, the script will look up the current user in PaperCut and clear the card number.
#>
#----------------[ Update Card Numbers - Declarations ]-------------------------------------------------

$extract = Import-Csv c:\scripts\results.tsv -Delimiter "`t" -Header Username,PrimaryCard,PIN,SecondaryCard
$successMessage = "Command executed successfully."
# $errorUserNotFound = "Error: Unable to execute server command. The user with name * could not be found."
$errorDuplicateCardID = "Error: Unable to execute server command. Tried to set *, but number is not unique.*"

$formatedDate = get-date -f yyyy-MM-dd
$logFile = "c:\scripts\logs\CardUpdates-$formatedDate.log"

#----------------[ Update Card Numbers - Main Execution ]-----------------------------------------------
ForEach ($user in $extract){

# Check if primary card is set in file
if ($user.PrimaryCard -ne "-")
   {
   # Update primary card for user
   $serverCommand = & "C:\Program Files\PaperCut MF\server\bin\win\server-command.exe" set-user-property $user.Username primary-card-number $user.PrimaryCard 2>&1 | ForEach-Object ToString

   # If duplicate card error, log error, lookup the user and clear current card (set to " ") before retrying
   if ($serverCommand -like $errorDuplicateCardID)
      {
      Out-File -FilePath $logFile -InputObject $ServerCommand -Append
      $duplicateUser = & "C:\Program Files\PaperCut MF\server\bin\win\server-command.exe" look-up-user-name-by-card-no $user.PrimaryCard
      & "C:\Program Files\PaperCut MF\server\bin\win\server-command.exe" set-user-property $duplicateUser primary-card-number " "
      $messageForLog1 = "Clearing conflicting primary card number $($user.PrimaryCard) from $duplicateUser"
      Out-File -FilePath $logFile -InputObject $messageForLog1 -Append
      & "C:\Program Files\PaperCut MF\server\bin\win\server-command.exe" set-user-property $user.Username primary-card-number $user.PrimaryCard
      }
   # If other error, write to log
   elseif ($serverCommand -ne $successMessage)
      {Out-File -FilePath $logFile -InputObject $ServerCommand -Append}
   }

# Check if secondary card is set in file
if ($user.SecondaryCard -ne "-")
   {
   #Update secondary card for user
   $serverCommand2 = & "C:\Program Files\PaperCut MF\server\bin\win\server-command.exe" set-user-property $user.Username secondary-card-number $user.SecondaryCard 2>&1 | ForEach-Object ToString

   # If duplicate card error, log error, lookup the user and clear current card (set to " ") before retrying
   if ($serverCommand2 -like $errorDuplicateCardID)
      {
      Out-File -FilePath $logFile -InputObject $ServerCommand2 -Append
      $duplicateUser2 = & "C:\Program Files\PaperCut MF\server\bin\win\server-command.exe" look-up-user-name-by-card-no $user.SecondaryCard
      & "C:\Program Files\PaperCut MF\server\bin\win\server-command.exe" set-user-property $duplicateUser2 secondary-card-number " "
      $messageForLog2 = "Clearing conflicting secondary card number $($user.SecondaryCard) from $duplicateUser2"
      Out-File -FilePath $logFile -InputObject $messageForLog2 -Append
      & "C:\Program Files\PaperCut MF\server\bin\win\server-command.exe" set-user-property $user.Username secondary-card-number $user.SecondaryCard
      }
   # If other error, write to log
   elseif ($serverCommand2 -ne $successMessage)
      {Out-File -FilePath $logFile -InputObject $ServerCommand2 -Append}
   }
}
}
