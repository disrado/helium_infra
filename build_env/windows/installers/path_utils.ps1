function Add-ToMachinePath
{
    param($Marker)
    $binPath = Split-Path $Marker -Parent
    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    if ($machinePath -notlike "*$binPath*") {
        $machinePath = "$machinePath;$binPath"
        [Environment]::SetEnvironmentVariable("Path", $machinePath, "Machine")
    }
    $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine")  # this session needs it too - vcpkg needs git visible right after Git installs
}

function Remove-FromMachinePath
{
    param($Marker)
    $binPath = Split-Path $Marker -Parent
    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $machinePath = ($machinePath -split ';' | Where-Object { $_ -ne $binPath }) -join ';'
    [Environment]::SetEnvironmentVariable("Path", $machinePath, "Machine")
}
