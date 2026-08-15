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
# depend on it, ensure the user ourselves and target it explicitly via -u. Setup logic lives
# in real .sh files fetched via curl (not inline heredocs) - PowerShell here-strings normalize
# to CRLF internally regardless of the source file's own line endings, which corrupts bash.
wsl -d $Distro -u root -- bash -c "curl -fsSL https://raw.githubusercontent.com/disrado/helium_infra/main/build_env/linux/devenv/ensure_user.sh -o /tmp/ensure_user.sh && chmod +x /tmp/ensure_user.sh && /tmp/ensure_user.sh $Username"
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to ensure user '$Username' exists - see the error above." -ForegroundColor Red
    exit $LASTEXITCODE
}

wsl -d $Distro -u $Username -- bash -c "curl -fsSL https://raw.githubusercontent.com/disrado/helium_infra/main/build_env/linux/devenv/devenv_setup.sh -o /tmp/devenv_setup.sh && chmod +x /tmp/devenv_setup.sh && /tmp/devenv_setup.sh"
if ($LASTEXITCODE -ne 0) {
    Write-Host "Setup failed - see the error above." -ForegroundColor Red
    exit $LASTEXITCODE
}
Write-Host "Done - dev environment ready in WSL distro '$Distro'." -ForegroundColor Green
