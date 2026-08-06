#Requires -RunAsAdministrator

<#
.SYNOPSIS
Installs the native Windows build toolchain under a single root. No Jenkins registration.
.EXAMPLE
.\bootstrap_toolchain.ps1
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

New-Item -ItemType Directory -Force -Path @($Root, "$Root\toolchain") | Out-Null

# vcpkg builds from source - real-time antivirus scanning tanks build times.
Add-MpPreference -ExclusionPath $Root

foreach ($name in $Packages) {
    & "Install-$name" -Root $Root
    & "Assert-${name}Installed" -Root $Root
}

# clang++ still needs vcvarsall's env vars - the onlogon session isn't a Developer Command Prompt.
$vcvarsall = "$Root\toolchain\vs-buildtools\VC\Auxiliary\Build\vcvarsall.bat"
$vcvarsOutput = cmd /c "`"$vcvarsall`" x64 && set"
foreach ($line in $vcvarsOutput) {
    if ($line -match '^(INCLUDE|LIB|LIBPATH)=(.*)$') {
        [Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Machine")
    }
}

if ($tempZip) { Remove-Item $tempZip, $tempExtract -Recurse -Force }

Write-Host "Toolchain ready." -ForegroundColor Green
