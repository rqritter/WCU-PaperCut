Param(  [Parameter(Mandatory=$true)][String]$computerName, 
        [String]$userName
     )

$taskXML = @"

<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Date>2019-03-18T12:54:31.5093515</Date>
    <Author>WCU\murrini</Author>
    <URI>\Start PaperCut</URI>
  </RegistrationInfo>
  <Triggers>
    <TimeTrigger>
      <StartBoundary>2019-03-18T12:57:15</StartBoundary>
      <Enabled>true</Enabled>
    </TimeTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>S-1-5-21-1757981266-1770027372-725345543-6281</UserId>
      <LogonType>InteractiveToken</LogonType>
      <RunLevel>LeastPrivilege</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>true</StopIfGoingOnBatteries>
    <AllowHardTerminate>false</AllowHardTerminate>
    <StartWhenAvailable>false</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>true</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT0S</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>"C:\Program Files (x86)\PaperCut MF Client\pc-client.exe"</Command>
    </Exec>
  </Actions>
</Task>

"@

function showMenu
{
    param (
        [string]$Title = 'Please Choose a Function'
    )
    # Clear-Host
    Write-Host "`n ===== $Title ====="
    
    Write-Host "1: Query the remote computer to see if PaperCut is running."
    Write-Host "2: Check if the PaperCut registry value exists"
    Write-Host "3: Run PaperCut remotely"
    Write-Host "`n Q: Press 'Q' to quit."
}
function checkPapercutRunning
{
    # query remote computer to see if Papercut is running
    tasklist /s $computerName /FI "Imagename eq pc-client.exe" /v
}

function checkPapercutReg
{
    # query remote computer to see if Papercut Autorun exists in the registry
    REG QUERY \\$computerName\HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run /v PaperCut_Client
}

function startPaperCutRemotely
{
    # create and run a scheduled task to start the PaperCut program remotely under a user
    # Check that $userName was specified. If not, prompt for it.
    if ($null -eq $userName){
       $username = Read-Host -Prompt 'Please specify the username in the format "wcu\username"'
       
    }
}

function showUsage
{
    Write-Host -ForegroundColor Red -BackgroundColor Black ""
    Write-Host -ForegroundColor Red -BackgroundColor Black "NAME"
    Write-Host -ForegroundColor Red -BackgroundColor Black "    Check-PapercutRemote.ps1"
    Write-Host -ForegroundColor Red -BackgroundColor Black ""
    Write-Host -ForegroundColor Red -BackgroundColor Black "SYNOPSIS"
    Write-Host -ForegroundColor Red -BackgroundColor Black "    Check to see if Papercut is running on a remote computer. Some troubleshooting options if not running"
    Write-Host -ForegroundColor Red -BackgroundColor Black ""
    Write-Host -ForegroundColor Red -BackgroundColor Black "SYNTAX"
    Write-Host -ForegroundColor Red -BackgroundColor Black "    Check-PapercutRemote.ps1 -computerName <String>"
    Write-Host -ForegroundColor Red -BackgroundColor Black ""
    Write-Host -ForegroundColor Red -BackgroundColor Black "PARAMETERS"
    Write-Host -ForegroundColor Red -BackgroundColor Black "    -computerName <String>"
    Write-Host -ForegroundColor Red -BackgroundColor Black "        Specifies the computer we are checking."
    Write-Host -ForegroundColor Red -BackgroundColor Black ""
    Write-Host -ForegroundColor Red -BackgroundColor Black "    -userName <String>"
    Write-Host -ForegroundColor Red -BackgroundColor Black "        Specifies the userName value for the user that should be running papercut."
    Write-Host -ForegroundColor Red -BackgroundColor Black ""
}

do
 {
     showMenu
     $selection = Read-Host "Please make a selection `n"
     switch ($selection)
     {
         '1' { 

            checkPapercutRunning
            Write-Host ""
            pause
             
         } '2' {
            checkPapercutReg
            Write-Host ""
            pause

         } '3' {
             'You chose option #3'
         }
     }
 }
 until ($selection -eq 'q')