. "$PSScriptRoot\..\nsis.ps1"

function Install-LLVM
{
    param($Root)
    Install-NsisTool -Id "LLVM.LLVM" -Version "22.1.8" -Location "$Root\toolchain\llvm" -Marker "$Root\toolchain\llvm\bin\clang++.exe"
}

function Uninstall-LLVM
{
    param($Root)
    Uninstall-NsisTool -Location "$Root\toolchain\llvm" -Marker "$Root\toolchain\llvm\bin\clang++.exe"
}

function Assert-LLVMInstalled
{
    param($Root)
    if (-not (Test-Path "$Root\toolchain\llvm\bin\clang++.exe")) { throw "LLVM install reported success but clang++.exe still doesn't exist" }
}
