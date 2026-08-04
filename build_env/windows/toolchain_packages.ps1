$ToolchainPackages = @(
    @{ Id = "Git.Git"; Version = "2.55.0.3"; Folder = "git"; Marker = "cmd\git.exe" }
    @{ Id = "Kitware.CMake"; Version = "4.4.1"; Folder = "cmake"; Marker = "bin\cmake.exe" }
    @{ Id = "Ninja-build.Ninja"; Version = "1.13.2"; Folder = "ninja"; Marker = "ninja.exe" }
    @{ Id = "LLVM.LLVM"; Version = "22.1.8"; Folder = "llvm"; Marker = "bin\clang++.exe" }
    @{ Id = "EclipseAdoptium.Temurin.21.JRE"; Version = "21.0.12.8"; Folder = "java"; Marker = "bin\java.exe" }
)
$VsBuildToolsId = "Microsoft.VisualStudio.2022.BuildTools"
$VsBuildToolsVersion = "17.14.37"
