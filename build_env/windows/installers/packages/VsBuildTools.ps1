# Microsoft's own VS Installer bootstrapper - dedicated to the VS product family, no other
# package will ever share this mechanism, so it lives here directly rather than as a shared installer type.
function Install-VsBuildTools
{
    param($Root)
    $id = "Microsoft.VisualStudio.2022.BuildTools"
    $version = "17.14.37"
    $location = "$Root\toolchain\vs-buildtools"
    $marker = "$location\VC\Auxiliary\Build\vcvarsall.bat"
    $installed = winget list --exact --id $id --accept-source-agreements 2>$null
    if ((Test-Path $marker) -and ($installed -match [regex]::Escape($version))) { return }
    winget install --exact --id $id --version $version --silent --accept-package-agreements --accept-source-agreements --override "--installPath $location --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended --quiet --wait --norestart"
    if ($LASTEXITCODE -eq 3010) {
        Write-Host "VS Build Tools installed - reboot recommended, continuing anyway." -ForegroundColor Yellow
    } elseif ($LASTEXITCODE -ne 0) {
        throw "VS Build Tools install failed (exit $LASTEXITCODE)"
    }
}

function Uninstall-VsBuildTools
{
    param($Root)
    $location = "$Root\toolchain\vs-buildtools"
    $vsInstaller = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vs_installer.exe"
    if (Test-Path $vsInstaller) {
        & $vsInstaller uninstall --installPath $location --quiet --wait --norestart
    } else {
        winget uninstall --exact --id "Microsoft.VisualStudio.2022.BuildTools" --silent --accept-source-agreements 2>$null
    }
}
