. "$PSScriptRoot\path_utils.ps1"

function Install-StaticExe
{
    param($Version, $Url, $Location, $Marker)
    if ((Test-Path $Marker) -and ((& $Marker --version) -eq $Version)) { return }
    New-Item -ItemType Directory -Force -Path $Location | Out-Null
    $zip = "$env:TEMP\$([guid]::NewGuid()).zip"
    Invoke-WebRequest -Uri $Url -OutFile $zip
    Expand-Archive -Path $zip -DestinationPath $Location -Force
    Remove-Item $zip -Force
    Add-ToMachinePath -Marker $Marker
}

function Uninstall-StaticExe
{
    param($Location, $Marker)
    Remove-Item -Recurse -Force $Location -ErrorAction SilentlyContinue
    Remove-FromMachinePath -Marker $Marker
}
