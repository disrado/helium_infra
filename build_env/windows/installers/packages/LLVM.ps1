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
