
<#PSScriptInfo

.VERSION 1.0

.GUID 84eeb4d0-d334-4f0f-a8f3-785925391662

.AUTHOR @sumanbhowmik

.COMPANYNAME 

.COPYRIGHT 
MonitorFSxForWindowsFileShareReachability.ps1

MIT License

Copyright (c) 2023 SumanBhowmik

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

.TAGS 

.LICENSEURI 

.PROJECTURI 

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES

#>

<# 

.DESCRIPTION 
This script can be used to monitor reachability of any FSx for Windows File System from a Windows based computer.

#> 

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#Start of script
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

Param()

# Checking if the PowerShell is elevated
if ( (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -eq $false) {
    
    Write-Host "The PowerShell window is not elevated. Please run the PowerShell as Administrator and try again" -ForegroundColor Red
    Write-Host -ForegroundColor Red "This PowerShell window is not elevated. Please run the PowerShell as Administrator and try again."
    Start-Sleep -Seconds 3
}

# User parameters
$FSxSharePath = Read-Host "Enter the FSx Share path"
[int]$Hours = Read-Host "For how long do you want to monitor the FSx (in Hours)"

#Removing if there is any existing Scheduled Task 
(if (Get-ScheduledTask -TaskName "TestFSxSharePath") { Unregister-ScheduledTask -TaskName "TestFSxSharePath" -Confirm:$false }) | Out-Null

# Creating directory to store script temp data:
if (!(Test-Path -Path "C:\FSxTestScripts")) { New-Item "C:\FSxTestScripts" -ItemType Directory -Force | Out-Null }
else { Remove-Item -Path "C:\FSxTestScripts" -Force; New-Item "C:\FSxTestScripts" -ItemType Directory -Force | Out-Null }

#Creating the PowerShell Script to monitor FSx 
'$FSxSharePath = ' + "`"$FSxSharePath`"" > "C:\FSxTestScripts\FSxTestScripts.ps1"
'[int]$Hours = ' + "$Hours" >> "C:\FSxTestScripts\FSxTestScripts.ps1"
'$EndTime = (Get-Date).AddHours($Hours)
for ($i = 0; (Get-Date) -le $EndTime; $i++) {
    if (Test-Path $FSxSharePath) { (Get-Date -Format "dd/MM/yyyy HH:mm:ss") + " : " + "The FSx Share $FSxSharePath is reachable" >> "C:\FSxTestScripts\FSxTestLog.log"}
    else { (Get-Date -Format "dd/MM/yyyy HH:mm:ss") + " : " + "The FSx Share $FSxSharePath is not reachable" >> "C:\FSxTestScripts\FSxTestLog.log"}
    Start-Sleep -Seconds 3
}' >> "C:\FSxTestScripts\FSxTestScripts.ps1"

#Creating the Task Schedular:
$Action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NonInteractive -NoLogo -NoProfile -File "C:\FSxTestScripts\FSxTestScripts.ps1"'
$Settings = New-ScheduledTaskSettingsSet
$principal = New-ScheduledTaskPrincipal -UserId 'NT AUTHORITY\SYSTEM' -RunLevel Highest -LogonType ServiceAccount
$Task = New-ScheduledTask -Action $Action -Settings $Settings -Principal $principal -Description "This scheduled task will test FSx share path $FSxSharePath and log the status in log file"
Register-ScheduledTask -TaskName "TestFSxSharePath" -InputObject $Task | Out-Null

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 
# End of Script #
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 