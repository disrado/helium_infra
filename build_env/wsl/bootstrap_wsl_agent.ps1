#Requires -RunAsAdministrator

<#
.SYNOPSIS
Sets up a WSL Jenkins agent (WSL2 + Docker) on a Windows machine.
.PARAMETER JenkinsUrl
Jenkins controller URL, e.g. https://jenkins.example.com/
.PARAMETER AgentSecret
Agent connection secret from Jenkins' node config page.
.PARAMETER AgentName
Jenkins node name.
.EXAMPLE
.\bootstrap_wsl_agent.ps1 -JenkinsUrl https://jenkins.example.com/ -AgentSecret abc123 -AgentName wsl-agent
#>

param(
    [string]$JenkinsUrl,
    [string]$AgentSecret,
    [string]$AgentName
)

$Distro = "Ubuntu"

if ($JenkinsUrl) { $JenkinsUrl = $JenkinsUrl.Trim() }
if ($AgentSecret) { $AgentSecret = $AgentSecret.Trim() }
if ($AgentName) { $AgentName = $AgentName.Trim() }

$missing = @()
if (-not $JenkinsUrl) { $missing += "-JenkinsUrl" }
if (-not $AgentSecret) { $missing += "-AgentSecret" }
if (-not $AgentName) { $missing += "-AgentName" }

if ($missing.Count -gt 0) {
    Write-Host "Missing required parameter(s): $($missing -join ', ')" -ForegroundColor Red
    Write-Host ""
    Write-Host "USAGE:"
    Write-Host "  .\bootstrap_wsl_agent.ps1 -JenkinsUrl <url> -AgentSecret <secret> -AgentName <name>"
    Write-Host ""
    Write-Host "PARAMETERS:"
    Write-Host "  -JenkinsUrl    Jenkins controller URL, e.g. https://jenkins.example.com/"
    Write-Host "  -AgentSecret   Agent connection secret from Jenkins' node config page."
    Write-Host "  -AgentName     Jenkins node name."
    Write-Host ""
    Write-Host "EXAMPLE:"
    Write-Host "  .\bootstrap_wsl_agent.ps1 -JenkinsUrl https://jenkins.example.com/ -AgentSecret abc123 -AgentName wsl-agent"
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
$wslConfig = if (Test-Path $wslConfigPath) { Get-Content $wslConfigPath -Raw } else { "" }
if ($wslConfig -notmatch "vmIdleTimeout") {
    # Strip any stale/orphaned [wsl2] section first rather than trying to detect and reuse
    # an existing header - more robust against whatever shape a prior run left behind.
    $kept = ($wslConfig -split "`r?`n") | Where-Object { $_ -notmatch "^\[wsl2\]\s*$" -and $_ -notmatch "vmIdleTimeout" }
    $wslConfig = (($kept -join "`n").TrimEnd()) + "`n`n[wsl2]`nvmIdleTimeout=-1`n"
    Set-Content -Path $wslConfigPath -Value $wslConfig
    wsl --shutdown
}

# Keeps dockerd/wsl-agent alive across idling and reboots. Current user, not SYSTEM
# (WSL distros are per-user). onlogon, not onstart - onstart fires once at boot and
# won't retry once you actually log in.
schtasks.exe /create /tn "wsl-autostart" /tr "powershell.exe -WindowStyle Hidden -Command wsl -d $Distro -- sleep infinity" /sc onlogon /ru "$env:USERNAME" /rl highest /f

# /create only takes effect next boot - run it once now too.
schtasks.exe /run /tn "wsl-autostart"

wsl -d $Distro -- bash -c "curl -fsSL https://raw.githubusercontent.com/disrado/helium_infra/main/build_env/wsl/agent/agent_setup.sh -o /tmp/agent_setup.sh && chmod +x /tmp/agent_setup.sh"
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to fetch agent_setup.sh - see the error above." -ForegroundColor Red
    exit $LASTEXITCODE
}

wsl -d $Distro -- /tmp/agent_setup.sh "$JenkinsUrl" "$AgentSecret" "$AgentName"
if ($LASTEXITCODE -ne 0) {
    Write-Host "Setup failed - see the error above." -ForegroundColor Red
    exit $LASTEXITCODE
}
Write-Host "Done - agent should now show connected in Jenkins." -ForegroundColor Green
