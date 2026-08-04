#Requires -RunAsAdministrator

<#
.SYNOPSIS
Sets up a native Windows Jenkins agent - installs the toolchain then registers with a Jenkins controller.
.PARAMETER JenkinsUrl
Jenkins controller URL, e.g. https://jenkins.example.com/
.PARAMETER AgentSecret
Agent connection secret from Jenkins' node config page.
.PARAMETER AgentName
Jenkins node name.
.EXAMPLE
.\bootstrap_windows_agent.ps1 -JenkinsUrl https://jenkins.example.com/ -AgentSecret abc123 -AgentName win-agent
#>

param(
    [string]$JenkinsUrl,
    [string]$AgentSecret,
    [string]$AgentName
)

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
    Write-Host "  .\bootstrap_windows_agent.ps1 -JenkinsUrl <url> -AgentSecret <secret> -AgentName <name>"
    Write-Host ""
    Write-Host "PARAMETERS:"
    Write-Host "  -JenkinsUrl    Jenkins controller URL, e.g. https://jenkins.example.com/"
    Write-Host "  -AgentSecret   Agent connection secret from Jenkins' node config page."
    Write-Host "  -AgentName     Jenkins node name."
    Write-Host ""
    Write-Host "EXAMPLE:"
    Write-Host "  .\bootstrap_windows_agent.ps1 -JenkinsUrl https://jenkins.example.com/ -AgentSecret abc123 -AgentName win-agent"
    exit 1
}

$ErrorActionPreference = "Stop"

$Root = "C:\jenkins-agent"

$toolchainScript = "$PSScriptRoot\bootstrap_toolchain.ps1"
$fetchedToolchainScript = -not (Test-Path $toolchainScript)
if ($fetchedToolchainScript) {
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/disrado/helium_infra/main/build_env/windows/bootstrap_toolchain.ps1" -OutFile $toolchainScript
}
. $toolchainScript
if ($fetchedToolchainScript) { Remove-Item $toolchainScript -Force }

New-Item -ItemType Directory -Force -Path "$Root\workDir" | Out-Null

$agentJarUrl = "$($JenkinsUrl.TrimEnd('/'))/jnlpJars/agent.jar"
Invoke-WebRequest -Uri $agentJarUrl -OutFile "$Root\agent.jar"

# No quotes below - every value here is space-free by design.
$javaExe = "$Toolchain\java\bin\java.exe"
$agentCmd = "$javaExe -jar $Root\agent.jar -url $JenkinsUrl -secret $AgentSecret -name $AgentName -workDir $Root\workDir -webSocket"

# schtasks.exe's /tr caps at 261 chars, secret+URL blow past it - Register-ScheduledTask has no such limit.
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -Command `"$agentCmd`""
$trigger = New-ScheduledTaskTrigger -AtLogOn -User "$env:USERNAME"
Register-ScheduledTask -TaskName "windows-agent-autostart" -Action $action -Trigger $trigger -User "$env:USERNAME" -RunLevel Highest -Force | Out-Null
Start-ScheduledTask -TaskName "windows-agent-autostart"

Write-Host "Done - agent should now show connected in Jenkins." -ForegroundColor Green
