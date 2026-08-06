#Requires -RunAsAdministrator

<#
.SYNOPSIS
Tears down the native Windows Jenkins agent - removes the toolchain and scheduled task.
.EXAMPLE
.\tear_down_windows_agent.ps1
#>

$ErrorActionPreference = "Stop"
$Root = "C:\jenkins-agent"

$sourceRoot = $PSScriptRoot
$tempZip = $null
if (-not (Test-Path "$sourceRoot\toolchain_packages.ps1")) {
    $tempZip = "$env:TEMP\helium_infra.zip"
    $tempExtract = "$env:TEMP\helium_infra_extract"
    Invoke-WebRequest -Uri "https://github.com/disrado/helium_infra/archive/refs/heads/main.zip" -OutFile $tempZip
    Expand-Archive -Path $tempZip -DestinationPath $tempExtract -Force
    $sourceRoot = "$tempExtract\helium_infra-main\build_env\windows"
}

. "$sourceRoot\toolchain_packages.ps1"
foreach ($name in $Packages) { . "$sourceRoot\installers\packages\$name.ps1" }

Unregister-ScheduledTask -TaskName "windows-agent-autostart" -Confirm:$false -ErrorAction SilentlyContinue

Get-Process java -ErrorAction SilentlyContinue | Stop-Process -Force

foreach ($name in $Packages) { & "Uninstall-$name" -Root $Root }

Remove-MpPreference -ExclusionPath $Root -ErrorAction SilentlyContinue

foreach ($var in @("INCLUDE", "LIB", "LIBPATH")) {
    [Environment]::SetEnvironmentVariable($var, $null, "Machine")
}

Remove-Item -Recurse -Force $Root -ErrorAction SilentlyContinue

if ($tempZip) { Remove-Item $tempZip, $tempExtract -Recurse -Force }

Write-Host "Windows agent torn down." -ForegroundColor Green
