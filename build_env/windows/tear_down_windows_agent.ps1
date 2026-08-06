#Requires -RunAsAdministrator

<#
.SYNOPSIS
Tears down the native Windows Jenkins agent - removes the toolchain and scheduled task.
.EXAMPLE
.\tear_down_windows_agent.ps1
#>

$ErrorActionPreference = "Stop"
$Root = "C:\jenkins-agent"

. "$PSScriptRoot\toolchain_packages.ps1"

$filesToLoad = @("installers\path_utils.ps1", "installers\winget.ps1", "installers\nsis.ps1", "installers\static_exe.ps1") + ($Packages | ForEach-Object { "installers\packages\$_.ps1" })
$fetchedFiles = @()
foreach ($f in $filesToLoad) {
    $path = "$PSScriptRoot\$f"
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Force -Path (Split-Path $path) | Out-Null
        Invoke-WebRequest -Uri "https://raw.githubusercontent.com/disrado/helium_infra/main/build_env/windows/$f" -OutFile $path
        $fetchedFiles += $path
    }
    . $path
}
foreach ($f in $fetchedFiles) { Remove-Item $f -Force }

Unregister-ScheduledTask -TaskName "windows-agent-autostart" -Confirm:$false -ErrorAction SilentlyContinue

Get-Process java -ErrorAction SilentlyContinue | Stop-Process -Force

foreach ($name in $Packages) { & "Uninstall-$name" -Root $Root }

Remove-MpPreference -ExclusionPath $Root -ErrorAction SilentlyContinue

foreach ($var in @("INCLUDE", "LIB", "LIBPATH")) {
    [Environment]::SetEnvironmentVariable($var, $null, "Machine")
}

Remove-Item -Recurse -Force $Root -ErrorAction SilentlyContinue

Write-Host "Windows agent torn down." -ForegroundColor Green
