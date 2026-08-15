#Requires -RunAsAdministrator

<#
.SYNOPSIS
Sets up a local Linux dev environment (WSL2) for building helium - no Jenkins agent, no Docker.
.PARAMETER Distro
WSL distro name to create/use. Defaults to "Ubuntu".
.EXAMPLE
.\bootstrap_wsl_devenv.ps1
.\bootstrap_wsl_devenv.ps1 -Distro helium-dev
#>

param(
    [string]$Distro = "Ubuntu"
)

$ErrorActionPreference = "Stop"

# wsl.exe's piped output is UTF-16LE (null byte per char), strip before matching.
$installedDistros = (wsl -l -q 2>$null) -replace "`0", "" | Where-Object { $_.Trim() -ne "" }
if ($installedDistros -notcontains $Distro) {
    wsl --install -d $Distro --no-launch
}

# First-time feature enablement needs a reboot before WSL actually works
wsl -d $Distro -- true
if ($LASTEXITCODE -ne 0) {
    Write-Host "WSL isn't usable yet - reboot required (first-time feature enablement). Reboot, then re-run this script."
    exit 1
}

$linuxSetup = @'
set -euo pipefail

sudo apt-get update && sudo apt-get install -y git-lfs zsh
git lfs install
sudo chsh -s "$(which zsh)" "$USER"

curl -fsSL https://raw.githubusercontent.com/disrado/helium_infra/main/build_env/linux/installers/install_build_packages.sh -o /tmp/install_build_packages.sh
curl -fsSL https://raw.githubusercontent.com/disrado/helium_infra/main/build_env/linux/installers/install_vcpkg.sh -o /tmp/install_vcpkg.sh
chmod +x /tmp/install_build_packages.sh /tmp/install_vcpkg.sh

sudo /tmp/install_build_packages.sh
/tmp/install_vcpkg.sh
grep -q '^export VCPKG_ROOT=' ~/.zshrc 2>/dev/null || echo 'export VCPKG_ROOT=$HOME/vcpkg' >> ~/.zshrc
'@

$linuxSetup | wsl -d $Distro -- bash -s --
if ($LASTEXITCODE -ne 0) {
    Write-Host "Setup failed - see the error above." -ForegroundColor Red
    exit $LASTEXITCODE
}
Write-Host "Done - dev environment ready in WSL distro '$Distro'." -ForegroundColor Green
