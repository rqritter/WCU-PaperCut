<#
.SYNOPSIS
  Name:Install-PCClient.ps1
  Install PaperCut Client and set to autostart

.NOTES
  Updated: 2019-7-30
  Author: Richie
  -New installers for 19.x.
  -Uninstall existing clients
#>
# Declarations

$InstallerFolder = "\\printserver.wcu.edu\share\clients\win"
$InstallerFile = "$($installerFolder)\pc-client-admin-deploy.msi"
$AutoRun = '"C:\Program Files\PaperCut MF Client\pc-client.exe"'
$MSIArguments = @(
    "/i"
    $InstallerFile
    "/qn"
    "/norestart"
    "ALLUSERS=1"
)

$appName = "PaperCut MF Client"

# Check if script is running as admin
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (!$currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){
    Write-Warning "Please re-run this script as an Administrator! Press any key to exit..."
    [void][System.Console]::ReadKey($true)
    Break
}

# Check for existing installations of PaperCut MF Client and uninstall if they exist

# Check for 32-bit install and uninstall if found
$uninstall32 = Get-ChildItem "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall" | foreach { Get-ItemProperty $_.PSPath } | Where-Object { $_ -match $appName }
if ($uninstall32) {
Write-Host "Uninstalling Previous 32-bit version of the PaperCut Client..."
start-process "msiexec.exe" -arg "/X $($uninstall32.PSChildName) /q" -Wait
Write-Host "Complete"
}

# Check for 64-bit install and uninstall if found
$uninstall64 = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" | foreach { Get-ItemProperty $_.PSPath } | Where-Object { $_ -match $appName }
if ($uninstall64) {
Write-Host "Uninstalling Previous 64-bit version of the PaperCut Client..."
start-process "msiexec.exe" -arg "/X $($uninstall64.PSChildName) /q" -Wait
Write-Host "Complete"
}

# Change $installerFolder variable if 32-bit OS
# Check using Environmental Variable
if (![Environment]::Is64BitOperatingSystem) {$installerFolder = '"\\printserver.wcu.edu\share\clients\win32"'}
# Check using WMI in case OS is old (kept Environmental check in case WMI is not working)
if ((Get-WmiObject Win32_OperatingSystem | Select-Object osarchitecture).osarchitecture -eq "32-bit") {$installerFolder = '"\\printserver.wcu.edu\share\clients\win32"'}


Write-Host "Installing PaperCut Client. Please wait..."
Start-Process "msiexec.exe" -ArgumentList $MSIArguments -Wait -NoNewWindow -WorkingDirectory $InstallerFolder
Set-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\Run -Name PaperCut_Client -Value $AutoRun
Write-Host "Starting the PaperCut Client..."
Start-Process $AutoRun
