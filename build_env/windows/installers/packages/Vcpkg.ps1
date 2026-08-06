# git clone + its own bootstrap script - a mechanism no other package uses, so it lives here directly.
function Install-Vcpkg
{
    param($Root)
    $location = "$Root\vcpkg"
    if ((Test-Path $location) -and -not (Test-Path "$location\.git")) {
        Remove-Item -Recurse -Force $location
    }
    if (-not (Test-Path "$location\.git")) {
        git clone https://github.com/microsoft/vcpkg $location
        if ($LASTEXITCODE -ne 0) { throw "git clone of vcpkg failed (exit $LASTEXITCODE)" }
    }
    New-Item -ItemType Directory -Force -Path "$location\cache" | Out-Null
    & "$location\bootstrap-vcpkg.bat" -disableMetrics
    [Environment]::SetEnvironmentVariable("VCPKG_ROOT", $location, "Machine")
    [Environment]::SetEnvironmentVariable("VCPKG_DEFAULT_BINARY_CACHE", "$location\cache", "Machine")
}

function Uninstall-Vcpkg
{
    param($Root)
    [Environment]::SetEnvironmentVariable("VCPKG_ROOT", $null, "Machine")
    [Environment]::SetEnvironmentVariable("VCPKG_DEFAULT_BINARY_CACHE", $null, "Machine")
    Remove-Item -Recurse -Force "$Root\vcpkg" -ErrorAction SilentlyContinue
}
