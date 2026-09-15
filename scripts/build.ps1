# FocusGuard build PowerShell
$ErrorActionPreference = "Stop"
$ContainerName = "focusguard-dev"
$ImageName = "ghcr.io/cirruslabs/flutter:3.24.3"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$WorkspaceDir = (Get-Item "$ScriptDir\..").FullName

Write-Host "==> [build] Building FocusGuard production release artifacts in Podman..." -ForegroundColor Cyan

$Cmd = @'
mkdir -p build/outputs
flutter build apk --release --no-tree-shake-icons
if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
  cp build/app/outputs/flutter-apk/app-release.apk build/outputs/focusguard-release.apk
  sha256sum build/outputs/focusguard-release.apk > build/outputs/focusguard-release.apk.sha256
  echo "==> [build] Generated build/outputs/focusguard-release.apk"
  ls -lh build/outputs/focusguard-release.apk
fi
'@

$running = podman ps --filter "name=^${ContainerName}$" --format "{{.Names}}"
if ($running -eq $ContainerName) {
    podman exec -w /workspace $ContainerName bash -c $Cmd
} else {
    podman run --rm -v "${WorkspaceDir}:/workspace:Z" -w /workspace $ImageName bash -c $Cmd
}

if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}
Write-Host "==> [build] Production build finished successfully." -ForegroundColor Green
