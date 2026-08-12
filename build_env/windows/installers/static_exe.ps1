. "$PSScriptRoot\path_utils.ps1"

function Install-StaticExe
{
    param($Version, $Url, $Location, $Marker)
    $versionFile = "$Marker.version"
    if ((Test-Path $Marker) -and (Test-Path $versionFile) -and ((Get-Content $versionFile -Raw) -eq $Version)) { return }
    New-Item -ItemType Directory -Force -Path $Location | Out-Null
    $zip = "$env:TEMP\$([guid]::NewGuid()).zip"
    $extractDir = "$env:TEMP\$([guid]::NewGuid())"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    # .NET's HttpWebRequest sends "Expect: 100-continue" by default, which GitHub's release CDN
    # doesn't handle gracefully - causes "the underlying connection was closed" on every attempt.
    [Net.ServicePointManager]::Expect100Continue = $false
    Invoke-WebRequest -Uri $Url -OutFile $zip -UseBasicParsing
    Expand-Archive -Path $zip -DestinationPath $extractDir -Force
    Remove-Item $zip -Force
    # Some releases (e.g. git-lfs) nest everything under a top-level version folder instead of
    # putting the exe at the archive root (like ninja-win.zip does) - locate it wherever it landed.
    $exeName = Split-Path $Marker -Leaf
    $found = Get-ChildItem -Path $extractDir -Filter $exeName -Recurse | Select-Object -First 1
    if (-not $found) { throw "$exeName not found anywhere in downloaded archive" }
    Copy-Item -Path $found.FullName -Destination $Marker -Force
    Remove-Item -Recurse -Force $extractDir
    Set-Content -Path $versionFile -Value $Version -NoNewline
    Add-ToMachinePath -Marker $Marker
}

function Uninstall-StaticExe
{
    param($Location, $Marker)
    Remove-Item -Recurse -Force $Location -ErrorAction SilentlyContinue
    Remove-FromMachinePath -Marker $Marker
}
