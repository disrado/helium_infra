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

Get-Process java -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

# best-effort: a package that failed mid-bootstrap shouldn't block cleanup of the rest.
foreach ($name in $Packages) {
    try {
        & "Uninstall-$name" -Root $Root
    } catch {
        Write-Warning "Uninstall-$name failed, continuing: $_"
    }
}

Remove-MpPreference -ExclusionPath $Root -ErrorAction SilentlyContinue

foreach ($var in @("INCLUDE", "LIB", "LIBPATH")) {
    [Environment]::SetEnvironmentVariable($var, $null, "Machine")
}

Remove-Item -Recurse -Force $Root -ErrorAction SilentlyContinue

if ($tempZip) { Remove-Item $tempZip, $tempExtract -Recurse -Force -ErrorAction SilentlyContinue }

Write-Host "Windows agent torn down." -ForegroundColor Green
