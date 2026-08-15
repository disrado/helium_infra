#Requires -RunAsAdministrator

<#
.SYNOPSIS
Sets up a local Linux dev environment (WSL2) for building helium - no Jenkins agent, no Docker.
.PARAMETER Distro
WSL distro name to create/use. Defaults to "Ubuntu".
.PARAMETER Username
Linux user to create/use inside the distro. Defaults to the current Windows username.
.EXAMPLE
.\bootstrap_wsl_devenv.ps1
.\bootstrap_wsl_devenv.ps1 -Distro helium-dev
#>

param(
    [string]$Distro = "Ubuntu",
    [string]$Username = $env:USERNAME.ToLower()
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

# WSL's first-launch OOBE can silently fall back to root instead of prompting - don't
# depend on it, ensure the user ourselves and target it explicitly via -u.
$ensureUser = @"
id -u $Username &>/dev/null || useradd -m -s /bin/bash -G sudo $Username
echo '$Username ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/$Username
"@
$ensureUser | wsl -d $Distro -u root -- bash -s --
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to ensure user '$Username' exists - see the error above." -ForegroundColor Red
    exit $LASTEXITCODE
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
RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
/tmp/install_vcpkg.sh
grep -q '^export VCPKG_ROOT=' ~/.zshenv 2>/dev/null || echo 'export VCPKG_ROOT=$HOME/vcpkg' >> ~/.zshenv

mkdir -p ~/src
[ -d ~/src/helium/.git ] || git clone https://github.com/disrado/helium.git ~/src/helium
git -C ~/src/helium submodule update --init deps/godot_cpp
'@

$linuxSetup | wsl -d $Distro -u $Username -- bash -s --
if ($LASTEXITCODE -ne 0) {
    Write-Host "Setup failed - see the error above." -ForegroundColor Red
    exit $LASTEXITCODE
}
Write-Host "Done - dev environment ready in WSL distro '$Distro'." -ForegroundColor Green
