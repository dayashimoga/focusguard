# FocusGuard clean PowerShell
$ErrorActionPreference = "SilentlyContinue"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$WorkspaceDir = (Get-Item "$ScriptDir\..").FullName

Write-Host "==> [clean] Cleaning FocusGuard build and test artifacts..." -ForegroundColor Cyan

Remove-Item -Recurse -Force "$WorkspaceDir\build" | Out-Null
Remove-Item -Recurse -Force "$WorkspaceDir\coverage" | Out-Null
Remove-Item -Recurse -Force "$WorkspaceDir\.dart_tool" | Out-Null
Remove-Item -Force "$WorkspaceDir\acceptance.json" | Out-Null
Remove-Item -Force "$WorkspaceDir\acceptance.html" | Out-Null

Write-Host "==> [clean] Project disposable resources cleaned." -ForegroundColor Green
