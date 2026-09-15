# FocusGuard test PowerShell
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$TestArgs
)

$ErrorActionPreference = "Stop"
$ContainerName = "focusguard-dev"
$ImageName = "ghcr.io/cirruslabs/flutter:3.24.3"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$WorkspaceDir = (Get-Item "$ScriptDir\..").FullName

Write-Host "==> [test] Running FocusGuard Automated Test Suite in Podman..." -ForegroundColor Cyan

$running = podman ps --filter "name=^${ContainerName}$" --format "{{.Names}}"
if ($running -eq $ContainerName) {
    podman exec -w /workspace $ContainerName flutter test --reporter=expanded $TestArgs
} else {
    podman run --rm -v "${WorkspaceDir}:/workspace:Z" -w /workspace $ImageName flutter test --reporter=expanded $TestArgs
}

if ($LASTEXITCODE -ne 0) {
    Write-Error "Tests failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}
Write-Host "==> [test] All tests completed successfully." -ForegroundColor Green
