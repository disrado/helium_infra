#Requires -RunAsAdministrator

<#
.SYNOPSIS
Sets up a Linux Jenkins agent (WSL2 + Docker) on a Windows machine.
.PARAMETER JenkinsUrl
Jenkins controller URL, e.g. https://jenkins.example.com/
.PARAMETER AgentSecret
Agent connection secret from Jenkins' node config page.
.PARAMETER AgentName
Name for the Jenkins node/container (e.g. wsl-agent).
.PARAMETER Distro
WSL distro name. Defaults to "Ubuntu".
.EXAMPLE
.\bootstrap_linux_agent.ps1 -JenkinsUrl https://jenkins.example.com/ -AgentSecret abc123 -AgentName wsl-agent
#>

param(
    [string]$JenkinsUrl,
    [string]$AgentSecret,
    [string]$AgentName,
    [string]$Distro = "Ubuntu"
)

$missing = @()
if (-not $JenkinsUrl) { $missing += "-JenkinsUrl" }
if (-not $AgentSecret) { $missing += "-AgentSecret" }
if (-not $AgentName) { $missing += "-AgentName" }

if ($missing.Count -gt 0) {
    Write-Host "Missing required parameter(s): $($missing -join ', ')" -ForegroundColor Red
    Write-Host ""
    Write-Host "USAGE:"
    Write-Host "  .\bootstrap_linux_agent.ps1 -JenkinsUrl <url> -AgentSecret <secret> -AgentName <name> [-Distro <distro>]"
    Write-Host ""
    Write-Host "PARAMETERS:"
    Write-Host "  -JenkinsUrl    Jenkins controller URL, e.g. https://jenkins.example.com/"
    Write-Host "  -AgentSecret   Agent connection secret from Jenkins' node config page."
    Write-Host "  -AgentName     Name for the Jenkins node/container (e.g. wsl-agent)."
    Write-Host "  -Distro        WSL distro name. Defaults to 'Ubuntu'."
    Write-Host ""
    Write-Host "EXAMPLE:"
    Write-Host "  .\bootstrap_linux_agent.ps1 -JenkinsUrl https://jenkins.example.com/ -AgentSecret abc123 -AgentName wsl-agent"
    exit 1
}

$ErrorActionPreference = "Stop"

# Install the distro if it's not there yet
if (-not (wsl -l -q 2>$null | Where-Object { $_ -match [regex]::Escape($Distro) })) {
    wsl --install -d $Distro --no-launch
}

# First-time feature enablement needs a reboot before WSL actually works
wsl -d $Distro -- true
if ($LASTEXITCODE -ne 0) {
    Write-Host "WSL isn't usable yet - reboot required (first-time feature enablement). Reboot, then re-run this script."
    exit 1
}

# vmIdleTimeout=-1: WSL2 suspends when idle by default, which drops wsl-agent's
# connection to Jenkins mid-build. Keep the VM running continuously instead.
$wslConfigPath = "$env:USERPROFILE\.wslconfig"
if (-not (Test-Path $wslConfigPath) -or (Get-Content $wslConfigPath -Raw) -notmatch "vmIdleTimeout") {
    Add-Content -Path $wslConfigPath -Value "`n[wsl2]`nvmIdleTimeout=-1`n"
    wsl --shutdown
}

# WSL2 doesn't auto-start on Windows boot - this brings it (and thus dockerd,
# and wsl-agent's --restart unless-stopped) back up after a real reboot.
schtasks.exe /create /tn "wsl-autostart" /tr "wsl.exe -d $Distro -- true" /sc onstart /ru SYSTEM /rl highest /f

$linuxSetup = @'
set -euo pipefail

# systemd (needed for dockerd, systemd-timesyncd)
sudo grep -q '^systemd=true' /etc/wsl.conf 2>/dev/null || printf '[boot]\nsystemd=true\n' | sudo tee -a /etc/wsl.conf >/dev/null

# clock-drift fix: systemd-timesyncd's ConditionVirtualization=!container trips
# on WSL2 (treated as a container even though it's a lightweight VM)
command -v systemd-timesyncd &>/dev/null || { sudo apt-get update -qq && sudo apt-get install -y systemd-timesyncd; }
sudo cp /usr/lib/systemd/system/systemd-timesyncd.service /etc/systemd/system/systemd-timesyncd.service
sudo sed -i '/ConditionVirtualization/d' /etc/systemd/system/systemd-timesyncd.service
sudo systemctl daemon-reload
sudo systemctl enable --now systemd-timesyncd

# native Docker Engine, not Docker Desktop. Patch out get.docker.com's own
# 20s WSL-detected sleep (it nags to use Docker Desktop instead) - no flag for this.
if ! command -v docker &>/dev/null; then
    curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
    sed -i 's/sleep 20/sleep 1/' /tmp/get-docker.sh
    sudo sh /tmp/get-docker.sh
    rm -f /tmp/get-docker.sh
    sudo usermod -aG docker "$USER"
fi

# passwordless sudo, for non-interactive remote automation
sudo grep -q "^$USER ALL=(ALL) NOPASSWD:ALL" /etc/sudoers.d/wsl-agent 2>/dev/null || \
    echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/wsl-agent >/dev/null

curl -fsSL https://raw.githubusercontent.com/disrado/helium_infra/main/build_env/linux/bootstrap.sh -o /tmp/bootstrap.sh
chmod +x /tmp/bootstrap.sh
trap 'rm -f /tmp/bootstrap.sh' EXIT

# sudo instead of sg: usermod -aG above doesn't take effect in this same session,
# and sg isn't guaranteed present on minimal images - root always has docker access anyway
sudo /tmp/bootstrap.sh "$1" "$2" "$3"
'@

$linuxSetup | wsl -d $Distro -- bash -s -- "$JenkinsUrl" "$AgentSecret" "$AgentName"
if ($LASTEXITCODE -ne 0) {
    Write-Host "Setup failed - see the error above." -ForegroundColor Red
    exit $LASTEXITCODE
}
Write-Host "Done - agent should now show connected in Jenkins." -ForegroundColor Green
