. "$PSScriptRoot\path_utils.ps1"

function Install-PipPackage
{
    param($Name, $PythonExe, $Marker)
    & $PythonExe -m pip install --upgrade $Name
    if ($LASTEXITCODE -ne 0) { throw "pip install $Name failed (exit $LASTEXITCODE)" }
    Add-ToMachinePath -Marker $Marker
}

function Uninstall-PipPackage
{
    param($Name, $PythonExe, $Marker)
    & $PythonExe -m pip uninstall -y $Name
    Remove-FromMachinePath -Marker $Marker
}
