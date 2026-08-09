. "$PSScriptRoot\..\winget.ps1"

function Install-Python
{
    param($Root)
    Install-WingetTool -Id "Python.Python.3.14" -Version "3.14.7" -Location "$Root\toolchain\python" -Marker "$Root\toolchain\python\python.exe"
}

function Uninstall-Python
{
    param($Root)
    Uninstall-WingetTool -Id "Python.Python.3.14" -Marker "$Root\toolchain\python\python.exe"
}

function Assert-PythonInstalled
{
    param($Root)
    if (-not (Test-Path "$Root\toolchain\python\python.exe")) { throw "Python install reported success but python.exe still doesn't exist" }
}
