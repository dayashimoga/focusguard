# FocusGuard dev-up PowerShell
$ErrorActionPreference = "Stop"
$ContainerName = "focusguard-dev"
$ImageName = "ghcr.io/cirruslabs/flutter:3.24.3"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$WorkspaceDir = (Get-Item "$ScriptDir\..").FullName

Write-Host "==> [dev-up] Starting FocusGuard development container..." -ForegroundColor Cyan

$running = podman ps --filter "name=^${ContainerName}$" --format "{{.Names}}"
if ($running -eq $ContainerName) {
    Write-Host "Container $ContainerName is already running." -ForegroundColor Green
    exit 0
}

$exists = podman ps -a --filter "name=^${ContainerName}$" --format "{{.Names}}"
if ($exists -eq $ContainerName) {
    Write-Host "Resuming existing stopped container $ContainerName..." -ForegroundColor Yellow
    podman start $ContainerName
    exit 0
}

Write-Host "Creating new container $ContainerName..." -ForegroundColor Cyan
podman run -d --name $ContainerName -v "${WorkspaceDir}:/workspace:Z" -w /workspace $ImageName tail -f /dev/null
Write-Host "Container $ContainerName started successfully." -ForegroundColor Green
