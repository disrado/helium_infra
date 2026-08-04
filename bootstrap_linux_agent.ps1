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

if ($JenkinsUrl) { $JenkinsUrl = $JenkinsUrl.Trim() }
if ($AgentSecret) { $AgentSecret = $AgentSecret.Trim() }
if ($AgentName) { $AgentName = $AgentName.Trim() }
if ($Distro) { $Distro = $Distro.Trim() }

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

# Keeps the outer VM from suspending (the distro instance itself is handled below).
$wslConfigPath = "$env:USERPROFILE\.wslconfig"
if (-not (Test-Path $wslConfigPath) -or (Get-Content $wslConfigPath -Raw) -notmatch "vmIdleTimeout") {
    Add-Content -Path $wslConfigPath -Value "`n[wsl2]`nvmIdleTimeout=-1`n"
    wsl --shutdown
}

# Keeps dockerd/wsl-agent alive across idling and reboots. Current user, not SYSTEM
# (WSL distros are per-user). onlogon, not onstart - onstart fires once at boot and
# won't retry once you actually log in.
schtasks.exe /create /tn "wsl-autostart" /tr "powershell.exe -WindowStyle Hidden -Command wsl -d $Distro -- sleep infinity" /sc onlogon /ru "$env:USERNAME" /rl highest /f

# /create only takes effect next boot - run it once now too.
schtasks.exe /run /tn "wsl-autostart"

$linuxSetup = @'
set -euo pipefail

# systemd (needed for dockerd, systemd-timesyncd)
sudo grep -q '^systemd=true' /etc/wsl.conf 2>/dev/null || printf '[boot]\nsystemd=true\n' | sudo tee -a /etc/wsl.conf >/dev/null

# clock-drift fix: systemd-timesyncd's ConditionVirtualization trips on WSL2
dpkg -s systemd-timesyncd &>/dev/null || { sudo apt-get update -qq && sudo apt-get install -y systemd-timesyncd; }
sudo cp /usr/lib/systemd/system/systemd-timesyncd.service /etc/systemd/system/systemd-timesyncd.service
sudo sed -i '/ConditionVirtualization/d' /etc/systemd/system/systemd-timesyncd.service
sudo systemctl daemon-reload
sudo systemctl enable --now systemd-timesyncd

# native Docker Engine; patches out get.docker.com's WSL-detected nag sleep
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

# sudo not sg: group change needs a new session anyway, and sg isn't always present
sudo /tmp/bootstrap.sh "$1" "$2" "$3"
'@

$linuxSetup | wsl -d $Distro -- bash -s -- "$JenkinsUrl" "$AgentSecret" "$AgentName"
if ($LASTEXITCODE -ne 0) {
    Write-Host "Setup failed - see the error above." -ForegroundColor Red
    exit $LASTEXITCODE
}
Write-Host "Done - agent should now show connected in Jenkins." -ForegroundColor Green
