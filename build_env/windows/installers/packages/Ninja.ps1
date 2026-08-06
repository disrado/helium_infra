. "$PSScriptRoot\..\static_exe.ps1"

function Install-Ninja
{
    param($Root)
    Install-StaticExe -Version "1.13.2" -Url "https://github.com/ninja-build/ninja/releases/download/v1.13.2/ninja-win.zip" -Location "$Root\toolchain\ninja" -Marker "$Root\toolchain\ninja\ninja.exe"
}

function Uninstall-Ninja
{
    param($Root)
    Uninstall-StaticExe -Location "$Root\toolchain\ninja" -Marker "$Root\toolchain\ninja\ninja.exe"
}
