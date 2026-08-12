. "$PSScriptRoot\..\static_exe.ps1"

function Install-GitLFS
{
    param($Root)
    Install-StaticExe -Version "3.7.1" -Url "https://github.com/git-lfs/git-lfs/releases/download/v3.7.1/git-lfs-windows-amd64-v3.7.1.zip" -Location "$Root\toolchain\git-lfs" -Marker "$Root\toolchain\git-lfs\git-lfs.exe"
    git lfs install --system
}

function Uninstall-GitLFS
{
    param($Root)
    Uninstall-StaticExe -Location "$Root\toolchain\git-lfs" -Marker "$Root\toolchain\git-lfs\git-lfs.exe"
}

function Assert-GitLFSInstalled
{
    param($Root)
    if (-not (Test-Path "$Root\toolchain\git-lfs\git-lfs.exe")) { throw "Git LFS install reported success but git-lfs.exe still doesn't exist" }
}
