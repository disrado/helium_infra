. "$PSScriptRoot\..\winget.ps1"

function Install-CMake
{
    param($Root)
    Install-WingetTool -Id "Kitware.CMake" -Version "4.4.1" -Location "$Root\toolchain\cmake" -Marker "$Root\toolchain\cmake\bin\cmake.exe"
}

function Uninstall-CMake
{
    param($Root)
    Uninstall-WingetTool -Id "Kitware.CMake" -Marker "$Root\toolchain\cmake\bin\cmake.exe"
}
