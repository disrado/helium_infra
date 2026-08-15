#Requires -RunAsAdministrator

<#
.SYNOPSIS
Sets up a local Windows dev environment for building helium - no Jenkins agent.
.EXAMPLE
.\bootstrap_windows_devenv.ps1
#>

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\devenv\bootstrap_toolchain.ps1"

$repoRoot = "$env:USERPROFILE\src\helium"
if (-not (Test-Path "$repoRoot\.git")) {
    git clone https://github.com/disrado/helium.git $repoRoot
}
git -C $repoRoot submodule update --init deps/godot_cpp

Write-Host "Done - dev environment ready." -ForegroundColor Green
