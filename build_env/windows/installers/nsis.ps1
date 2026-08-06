. "$PSScriptRoot\winget.ps1"

# NSIS installers don't clean up old files on upgrade - wipe first when a different version is pinned.
function Install-NsisTool
{
    param($Id, $Version, $Location, $Marker)
    $installed = winget list --exact --id $Id --accept-source-agreements 2>$null
    $upToDate = (Test-Path $Marker) -and ($installed -match [regex]::Escape($Version))
    if ((Test-Path $Location) -and -not $upToDate) { Remove-Item -Recurse -Force $Location }
    Install-WingetTool -Id $Id -Version $Version -Location $Location -Marker $Marker
}

function Uninstall-NsisTool
{
    param($Location, $Marker)
    $uninstaller = "$Location\Uninstall.exe"
    if (Test-Path $uninstaller) { & $uninstaller /S | Out-Null }
    Remove-FromMachinePath -Marker $Marker
}
