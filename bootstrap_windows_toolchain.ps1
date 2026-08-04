#Requires -RunAsAdministrator

<#
.SYNOPSIS
Installs the native Windows build toolchain under a single root. No Jenkins registration.
.EXAMPLE
.\bootstrap_windows_toolchain.ps1
#>

$ErrorActionPreference = "Stop"

$Root = "C:\jenkins-agent"

$GitVersion = "2.55.0.3"
$CMakeVersion = "4.4.1"
$NinjaVersion = "1.13.2"
$LlvmVersion = "22.1.8"
$JavaVersion = "21.0.12.8"
$VsBuildToolsVersion = "17.14.37"

$Toolchain = "$Root\toolchain"
New-Item -ItemType Directory -Force -Path @($Root, $Toolchain) | Out-Null

# vcpkg builds from source - real-time antivirus scanning tanks build times.
Add-MpPreference -ExclusionPath $Root

function Install-Tool
{
    param($Id, $Version, $Location, $Marker)
    $installed = winget list --exact --id $Id --accept-source-agreements 2>$null
    if ((Test-Path $Marker) -and ($installed -match [regex]::Escape($Version))) { return }
    winget install --exact --id $Id --version $Version --location $Location --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
    if ($LASTEXITCODE -ne 0) { throw "winget install failed for $Id (exit $LASTEXITCODE)" }
}

Install-Tool -Id "Git.Git" -Version $GitVersion -Location "$Toolchain\git" -Marker "$Toolchain\git\cmd\git.exe"
Install-Tool -Id "Kitware.CMake" -Version $CMakeVersion -Location "$Toolchain\cmake" -Marker "$Toolchain\cmake\bin\cmake.exe"
Install-Tool -Id "Ninja-build.Ninja" -Version $NinjaVersion -Location "$Toolchain\ninja" -Marker "$Toolchain\ninja\ninja.exe"
Install-Tool -Id "LLVM.LLVM" -Version $LlvmVersion -Location "$Toolchain\llvm" -Marker "$Toolchain\llvm\bin\clang++.exe"
Install-Tool -Id "EclipseAdoptium.Temurin.21.JRE" -Version $JavaVersion -Location "$Toolchain\java" -Marker "$Toolchain\java\bin\java.exe"

# Standalone LLVM above is the compiler - only need the SDK + linker here.
$vcvarsall = "$Toolchain\vs-buildtools\VC\Auxiliary\Build\vcvarsall.bat"
$vsInstalled = winget list --exact --id Microsoft.VisualStudio.2022.BuildTools --accept-source-agreements 2>$null
if (-not ((Test-Path $vcvarsall) -and ($vsInstalled -match [regex]::Escape($VsBuildToolsVersion)))) {
    winget install --exact --id Microsoft.VisualStudio.2022.BuildTools --version $VsBuildToolsVersion --silent --accept-package-agreements --accept-source-agreements --override "--installPath $Toolchain\vs-buildtools --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended --quiet --wait --norestart"
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

if ((Test-Path "$Root\vcpkg") -and -not (Test-Path "$Root\vcpkg\.git")) {
    Remove-Item -Recurse -Force "$Root\vcpkg"
}
if (-not (Test-Path "$Root\vcpkg\.git")) {
    git clone https://github.com/microsoft/vcpkg "$Root\vcpkg"
    if ($LASTEXITCODE -ne 0) { throw "git clone of vcpkg failed (exit $LASTEXITCODE)" }
}
New-Item -ItemType Directory -Force -Path "$Root\vcpkg\cache" | Out-Null
& "$Root\vcpkg\bootstrap-vcpkg.bat" -disableMetrics
[Environment]::SetEnvironmentVariable("VCPKG_ROOT", "$Root\vcpkg", "Machine")
[Environment]::SetEnvironmentVariable("VCPKG_DEFAULT_BINARY_CACHE", "$Root\vcpkg\cache", "Machine")

# clang++ still needs vcvarsall's env vars - the onlogon session isn't a Developer Command Prompt.
$vcvarsOutput = cmd /c "`"$vcvarsall`" x64 && set"
foreach ($line in $vcvarsOutput) {
    if ($line -match '^(INCLUDE|LIB|LIBPATH)=(.*)$') {
        [Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Machine")
    }
}

Write-Host "Toolchain ready." -ForegroundColor Green
