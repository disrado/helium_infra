. "$PSScriptRoot\..\pip.ps1"

function Install-Scons
{
    param($Root)
    Install-PipPackage -Name "scons" -PythonExe "$Root\toolchain\python\python.exe" -Marker "$Root\toolchain\python\Scripts\scons.exe"
}

function Uninstall-Scons
{
    param($Root)
    Uninstall-PipPackage -Name "scons" -PythonExe "$Root\toolchain\python\python.exe" -Marker "$Root\toolchain\python\Scripts\scons.exe"
}

function Assert-SconsInstalled
{
    param($Root)
    if (-not (Test-Path "$Root\toolchain\python\Scripts\scons.exe")) { throw "scons install reported success but scons.exe still doesn't exist" }
}
