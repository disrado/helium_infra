#Requires -RunAsAdministrator

<#
.SYNOPSIS
Tears down the native Windows Jenkins agent - removes the toolchain and scheduled task.
.EXAMPLE
.\tear_down_windows_agent.ps1
#>

$ErrorActionPreference = "Stop"
$Root = "C:\jenkins-agent"

$packagesScript = "$PSScriptRoot\toolchain_packages.ps1"
$fetchedPackagesScript = -not (Test-Path $packagesScript)
if ($fetchedPackagesScript) {
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/disrado/helium_infra/main/build_env/windows/toolchain_packages.ps1" -OutFile $packagesScript
}
. $packagesScript
if ($fetchedPackagesScript) { Remove-Item $packagesScript -Force }

Unregister-ScheduledTask -TaskName "windows-agent-autostart" -Confirm:$false -ErrorAction SilentlyContinue

Get-Process java -ErrorAction SilentlyContinue | Stop-Process -Force

foreach ($pkg in $ToolchainPackages) {
    if ($pkg.Id -eq "LLVM.LLVM") {
        # LLVM's winget manifest doesn't map --silent to a real uninstaller flag - falls back to its GUI.
        $llvmUninstaller = "$Root\toolchain\$($pkg.Folder)\Uninstall.exe"
        if (Test-Path $llvmUninstaller) { & $llvmUninstaller /S | Out-Null }
    } else {
        winget uninstall --exact --id $pkg.Id --silent --accept-source-agreements 2>$null
    }
}

# Same winget-silent gap as LLVM - call the VS Installer CLI directly instead.
$vsInstaller = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vs_installer.exe"
if (Test-Path $vsInstaller) {
    & $vsInstaller uninstall --installPath "$Root\toolchain\vs-buildtools" --quiet --wait --norestart
} else {
    winget uninstall --exact --id $VsBuildToolsId --silent --accept-source-agreements 2>$null
}

Remove-MpPreference -ExclusionPath $Root -ErrorAction SilentlyContinue

$machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
$toolchainPaths = $ToolchainPackages | ForEach-Object {
    $dir = Split-Path $_.Marker -Parent
    if ($dir) { "$Root\toolchain\$($_.Folder)\$dir" } else { "$Root\toolchain\$($_.Folder)" }
}
$machinePath = ($machinePath -split ';' | Where-Object { $toolchainPaths -notcontains $_ }) -join ';'
[Environment]::SetEnvironmentVariable("Path", $machinePath, "Machine")

foreach ($var in @("VCPKG_ROOT", "VCPKG_DEFAULT_BINARY_CACHE", "INCLUDE", "LIB", "LIBPATH")) {
    [Environment]::SetEnvironmentVariable($var, $null, "Machine")
}

Remove-Item -Recurse -Force $Root -ErrorAction SilentlyContinue

Write-Host "Windows agent torn down." -ForegroundColor Green
