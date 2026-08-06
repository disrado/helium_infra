. "$PSScriptRoot\..\winget.ps1"

function Install-Git
{
    param($Root)
    Install-WingetTool -Id "Git.Git" -Version "2.55.0.3" -Location "$Root\toolchain\git" -Marker "$Root\toolchain\git\cmd\git.exe"
}

function Uninstall-Git
{
    param($Root)
    Uninstall-WingetTool -Id "Git.Git" -Marker "$Root\toolchain\git\cmd\git.exe"
}
