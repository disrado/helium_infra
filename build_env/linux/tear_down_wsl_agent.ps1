#Requires -RunAsAdministrator

<#
.SYNOPSIS
Tears down the WSL Jenkins agent - unregisters the distro and removes bootstrap artifacts.
.EXAMPLE
.\tear_down_wsl_agent.ps1
#>

$ErrorActionPreference = "Stop"
$Distro = "Ubuntu"

try { schtasks.exe /delete /tn "wsl-autostart" /f } catch { Write-Warning "scheduled task removal failed, continuing: $_" }

try { wsl --unregister $Distro } catch { Write-Warning "wsl unregister failed, continuing: $_" }

try {
    $wslConfigPath = "$env:USERPROFILE\.wslconfig"
    if (Test-Path $wslConfigPath) {
        (Get-Content $wslConfigPath) | Where-Object { $_ -notmatch "vmIdleTimeout" } | Set-Content $wslConfigPath
    }
} catch {
    Write-Warning ".wslconfig cleanup failed, continuing: $_"
}

Write-Host "WSL agent torn down." -ForegroundColor Green
