$ErrorActionPreference = "Stop"

$workspacesRoot = Split-Path $env:WORKSPACE -Parent

Get-ChildItem $workspacesRoot -Directory | ForEach-Object {
    Remove-Item "$($_.FullName)\build" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$($_.FullName)\deps\godot\bin" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$($_.FullName)\deps\godot\.sconsign.dblite" -Force -ErrorAction SilentlyContinue
}
