#Requires -RunAsAdministrator

<#
.SYNOPSIS
Tears down the WSL Jenkins agent - unregisters the distro and removes bootstrap artifacts.
.EXAMPLE
.\tear_down_wsl_agent.ps1
#>

$ErrorActionPreference = "Stop"
$Distro = "Ubuntu"

schtasks.exe /delete /tn "wsl-autostart" /f

wsl --unregister $Distro

Write-Host "WSL agent torn down." -ForegroundColor Green
