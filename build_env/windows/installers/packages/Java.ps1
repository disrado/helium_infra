. "$PSScriptRoot\..\winget.ps1"

function Install-Java
{
    param($Root)
    Install-WingetTool -Id "EclipseAdoptium.Temurin.21.JRE" -Version "21.0.12.8" -Location "$Root\toolchain\java" -Marker "$Root\toolchain\java\bin\java.exe"
}

function Uninstall-Java
{
    param($Root)
    Uninstall-WingetTool -Id "EclipseAdoptium.Temurin.21.JRE" -Marker "$Root\toolchain\java\bin\java.exe"
}
