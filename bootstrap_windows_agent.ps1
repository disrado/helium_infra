#Requires -RunAsAdministrator

<#
.SYNOPSIS
Sets up a native Windows Jenkins agent (toolchain + agent service) on a Windows machine.
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

# Single root: everything bootstrap brings to the machine lives here, for easy teardown later.
$Root = "C:\jenkins-agent"
$Toolchain = "$Root\toolchain"
New-Item -ItemType Directory -Force -Path @($Root, $Toolchain, "$Root\vcpkg\cache", "$Root\workDir") | Out-Null

# vcpkg builds from source (thousands of small files) - real-time scanning tanks build times.
Add-MpPreference -ExclusionPath $Root

function Install-Tool
{
    param($Id, $Location, $Marker)
    if (Test-Path $Marker) { return }
    winget install --exact --id $Id --location $Location --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
    if ($LASTEXITCODE -ne 0) { throw "winget install failed for $Id (exit $LASTEXITCODE)" }
}

Install-Tool -Id "Git.Git" -Location "$Toolchain\git" -Marker "$Toolchain\git\cmd\git.exe"
Install-Tool -Id "Kitware.CMake" -Location "$Toolchain\cmake" -Marker "$Toolchain\cmake\bin\cmake.exe"
Install-Tool -Id "Ninja-build.Ninja" -Location "$Toolchain\ninja" -Marker "$Toolchain\ninja\ninja.exe"
Install-Tool -Id "LLVM.LLVM" -Location "$Toolchain\llvm" -Marker "$Toolchain\llvm\bin\clang++.exe"
Install-Tool -Id "EclipseAdoptium.Temurin.21.JRE" -Location "$Toolchain\java" -Marker "$Toolchain\java\bin\java.exe"

# Standalone LLVM above is the compiler - this is just for the Windows SDK + linker.
$vcvarsall = "$Toolchain\vs-buildtools\VC\Auxiliary\Build\vcvarsall.bat"
if (-not (Test-Path $vcvarsall)) {
    winget install --exact --id Microsoft.VisualStudio.2022.BuildTools --silent --accept-package-agreements --accept-source-agreements --override "--installPath $Toolchain\vs-buildtools --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended --quiet --wait --norestart"
    if ($LASTEXITCODE -eq 3010) {
        Write-Host "VS Build Tools installed - reboot recommended, continuing anyway." -ForegroundColor Yellow
    } elseif ($LASTEXITCODE -ne 0) {
        throw "VS Build Tools install failed (exit $LASTEXITCODE)"
    }
}

$machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
foreach ($p in @("$Toolchain\git\cmd", "$Toolchain\cmake\bin", "$Toolchain\ninja", "$Toolchain\llvm\bin", "$Toolchain\java\bin")) {
    if ($machinePath -notlike "*$p*") { $machinePath = "$machinePath;$p" }
}
[Environment]::SetEnvironmentVariable("Path", $machinePath, "Machine")
$env:Path = $machinePath  # this session needs it too, for vcpkg/vcvarsall below

if (-not (Test-Path "$Root\vcpkg\.git")) {
    git clone https://github.com/microsoft/vcpkg "$Root\vcpkg"
}
& "$Root\vcpkg\bootstrap-vcpkg.bat" -disableMetrics
[Environment]::SetEnvironmentVariable("VCPKG_ROOT", "$Root\vcpkg", "Machine")
[Environment]::SetEnvironmentVariable("VCPKG_DEFAULT_BINARY_CACHE", "$Root\vcpkg\cache", "Machine")

# clang++ still links against MSVC/Windows SDK libs - needs vcvarsall's env vars persisted,
# since the agent's onlogon session isn't a Developer Command Prompt.
$vcvarsOutput = cmd /c "`"$vcvarsall`" x64 && set"
foreach ($line in $vcvarsOutput) {
    if ($line -match '^(INCLUDE|LIB|LIBPATH)=(.*)$') {
        [Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Machine")
    }
}

$agentJarUrl = "$($JenkinsUrl.TrimEnd('/'))/jnlpJars/agent.jar"
Invoke-WebRequest -Uri $agentJarUrl -OutFile "$Root\agent.jar"

# No quotes below - every value here is space-free by design, avoids schtasks' nested-quote hazard.
$javaExe = "$Toolchain\java\bin\java.exe"
$agentCmd = "$javaExe -jar $Root\agent.jar -url $JenkinsUrl -secret $AgentSecret -name $AgentName -workDir $Root\workDir"
schtasks.exe /create /tn "windows-agent-autostart" /tr "powershell.exe -WindowStyle Hidden -Command $agentCmd" /sc onlogon /ru "$env:USERNAME" /rl highest /f
schtasks.exe /run /tn "windows-agent-autostart"
if ($LASTEXITCODE -ne 0) {
    Write-Host "Setup failed - see the error above." -ForegroundColor Red
    exit $LASTEXITCODE
}
Write-Host "Done - agent should now show connected in Jenkins." -ForegroundColor Green
