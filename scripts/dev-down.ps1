# FocusGuard dev-down PowerShell
$ErrorActionPreference = "SilentlyContinue"
$ContainerName = "focusguard-dev"

Write-Host "==> [dev-down] Stopping and removing FocusGuard development container..." -ForegroundColor Cyan

$exists = podman ps -a --filter "name=^${ContainerName}$" --format "{{.Names}}"
if ($exists -eq $ContainerName) {
    podman stop -t 2 $ContainerName | Out-Null
    podman rm $ContainerName | Out-Null
    Write-Host "Container $ContainerName stopped and removed." -ForegroundColor Green
} else {
    Write-Host "Container $ContainerName was not running." -ForegroundColor Yellow
}
