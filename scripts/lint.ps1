# FocusGuard lint PowerShell
$ErrorActionPreference = "Stop"
$ContainerName = "focusguard-dev"
$ImageName = "ghcr.io/cirruslabs/flutter:3.24.3"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$WorkspaceDir = (Get-Item "$ScriptDir\..").FullName

Write-Host "==> [lint] Checking code formatting and static analysis in Podman..." -ForegroundColor Cyan

$Cmd = "dart format --set-exit-if-changed lib test && flutter analyze"

$running = podman ps --filter "name=^${ContainerName}$" --format "{{.Names}}"
if ($running -eq $ContainerName) {
    podman exec -w /workspace $ContainerName bash -c $Cmd
} else {
    podman run --rm -v "${WorkspaceDir}:/workspace:Z" -w /workspace $ImageName bash -c $Cmd
}

if ($LASTEXITCODE -ne 0) {
    Write-Error "Lint failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}
Write-Host "==> [lint] Formatting and analysis passed without errors." -ForegroundColor Green
