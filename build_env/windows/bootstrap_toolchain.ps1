#Requires -RunAsAdministrator

<#
.SYNOPSIS
Installs the native Windows build toolchain under a single root. No Jenkins registration.
.EXAMPLE
.\bootstrap_toolchain.ps1
#>

$ErrorActionPreference = "Stop"

$Root = "C:\jenkins-agent"

$packagesScript = "$PSScriptRoot\toolchain_packages.ps1"
$fetchedFiles = @()
if (-not (Test-Path $packagesScript)) {
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/disrado/helium_infra/main/build_env/windows/toolchain_packages.ps1" -OutFile $packagesScript
    $fetchedFiles += $packagesScript
}
. $packagesScript

$filesToLoad = @("installers\path_utils.ps1", "installers\winget.ps1", "installers\nsis.ps1", "installers\static_exe.ps1") + ($Packages | ForEach-Object { "installers\packages\$_.ps1" })
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
foreach ($dir in @("$PSScriptRoot\installers\packages", "$PSScriptRoot\installers")) {
    if ((Test-Path $dir) -and -not (Get-ChildItem $dir)) { Remove-Item $dir -Force }
}

New-Item -ItemType Directory -Force -Path @($Root, "$Root\toolchain") | Out-Null

# vcpkg builds from source - real-time antivirus scanning tanks build times.
Add-MpPreference -ExclusionPath $Root

foreach ($name in $Packages) { & "Install-$name" -Root $Root }

# clang++ still needs vcvarsall's env vars - the onlogon session isn't a Developer Command Prompt.
$vcvarsall = "$Root\toolchain\vs-buildtools\VC\Auxiliary\Build\vcvarsall.bat"
$vcvarsOutput = cmd /c "`"$vcvarsall`" x64 && set"
foreach ($line in $vcvarsOutput) {
    if ($line -match '^(INCLUDE|LIB|LIBPATH)=(.*)$') {
        [Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Machine")
    }
}

Write-Host "Toolchain ready." -ForegroundColor Green
