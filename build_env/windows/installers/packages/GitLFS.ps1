. "$PSScriptRoot\..\winget.ps1"

function Install-GitLFS
{
    param($Root)
    Install-WingetTool -Id "GitHub.GitLFS" -Version "3.7.1" -Location "$Root\toolchain\git-lfs" -Marker "$Root\toolchain\git-lfs\git-lfs.exe"
    git lfs install --system
}

function Uninstall-GitLFS
{
    param($Root)
    Uninstall-WingetTool -Id "GitHub.GitLFS" -Marker "$Root\toolchain\git-lfs\git-lfs.exe"
}

function Assert-GitLFSInstalled
{
    param($Root)
    if (-not (Test-Path "$Root\toolchain\git-lfs\git-lfs.exe")) { throw "Git LFS install reported success but git-lfs.exe still doesn't exist" }
}
