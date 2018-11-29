<#
.SYNOPSIS
  Name:Install-PCClient.ps1
  Install PaperCut Client and set to autostart

.NOTES
  Updated: 2018-11-27
  Author: Richie
  ToDo:
     1. test
#>
# Declarations

$InstallerFolder = "\\printserver.wcu.edu\share\clients\win"
$InstallerFile = "$($installerFolder)\pc-client-admin-deploy.msi"
$AutoRun = '"C:\Program Files (x86)\PaperCut MF Client\pc-client.exe"'
$MSIArguments = @(
    "/i"
    $InstallerFile
    "/qn"
    "/norestart"
    "ALLUSERS=1"
)

# Check if script is running as admin
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (!$currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){
    Write-Warning "Please re-run this script as an Administrator! Press any key to exit..."
    [void][System.Console]::ReadKey($true)
    Break
}

Write-host "Installing PaperCut Client. Please wait..."
Start-Process "msiexec.exe" -ArgumentList $MSIArguments -Wait -NoNewWindow -WorkingDirectory $InstallerFolder
New-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\Run -Name PaperCut_Client -PropertyType String -Value $AutoRun
Start-Process $AutoRun

