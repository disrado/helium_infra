. "$PSScriptRoot\path_utils.ps1"

function Install-WingetTool
{
    param($Id, $Version, $Location, $Marker)
    $installed = winget list --exact --id $Id --accept-source-agreements 2>$null
    if ((Test-Path $Marker) -and ($installed -match [regex]::Escape($Version))) { return }
    winget install --exact --id $Id --version $Version --location $Location --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
    if ($LASTEXITCODE -ne 0) { throw "winget install failed for $Id (exit $LASTEXITCODE)" }
    Add-ToMachinePath -Marker $Marker
}

function Uninstall-WingetTool
{
    param($Id, $Marker)
    winget uninstall --exact --id $Id --silent --accept-source-agreements 2>$null
    Remove-FromMachinePath -Marker $Marker
}
