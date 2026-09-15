# FocusGuard Acceptance Certification Script (PowerShell)
$ErrorActionPreference = "Stop"

$ContainerName = "focusguard-dev"
$ImageName = "ghcr.io/cirruslabs/flutter:3.24.3"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$WorkspaceDir = Split-Path -Parent $ScriptDir

Write-Host "==> [acceptance] Running FocusGuard Production Certification Pipeline..." -ForegroundColor Cyan

$CmdArgs = $args -join " "
$Cmd = "dart run acceptance/acceptance_runner.dart $CmdArgs"

$containerRunning = podman ps --filter "name=^$ContainerName$" --format "{{.Names}}" 2>$null
if ($containerRunning -eq $ContainerName) {
    podman exec -w /workspace $ContainerName bash -c "$Cmd"
} else {
    Write-Host "Dev container '$ContainerName' is not running. Starting one-shot runner container..." -ForegroundColor Yellow
    podman run --rm -v "${WorkspaceDir}:/workspace:Z" -w /workspace $ImageName bash -c "$Cmd"
}

if ($LASTEXITCODE -ne 0) {
    Write-Error "Acceptance certification failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}

Write-Host "==> [acceptance] Certification pipeline completed successfully." -ForegroundColor Green
