# FocusGuard coverage PowerShell
$ErrorActionPreference = "Stop"
$ContainerName = "focusguard-dev"
$ImageName = "ghcr.io/cirruslabs/flutter:3.24.3"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$WorkspaceDir = (Get-Item "$ScriptDir\..").FullName

Write-Host "==> [coverage] Running tests with code coverage in Podman..." -ForegroundColor Cyan

$Cmd = @'
rm -rf coverage/
flutter test --coverage
if [ -f "coverage/lcov.info" ]; then
  TOTAL_LINES=$(grep -E "^DA:[0-9]+,[0-9]+" coverage/lcov.info | wc -l || true)
  HIT_LINES=$(grep -E "^DA:[0-9]+,[1-9][0-9]*" coverage/lcov.info | wc -l || true)
  if [ "$TOTAL_LINES" -gt 0 ]; then
    COVERAGE_PCT=$(awk -v hit="$HIT_LINES" -v tot="$TOTAL_LINES" "BEGIN { printf \"%.2f\", (hit/tot)*100 }")
    echo "========================================="
    echo "  Total Instrumented Lines : $TOTAL_LINES"
    echo "  Lines Covered            : $HIT_LINES"
    echo "  Overall Code Coverage    : ${COVERAGE_PCT}%"
    echo "========================================="
    THRESHOLD_MET=$(awk -v cov="$COVERAGE_PCT" "BEGIN { print (cov >= 90.0) ? 1 : 0 }")
    if [ "$THRESHOLD_MET" -eq 1 ]; then
      echo "==> [coverage] PASS: Coverage ${COVERAGE_PCT}% meets or exceeds required 90.0% threshold."
    else
      echo "==> [coverage] FAIL: Coverage ${COVERAGE_PCT}% is below required 90.0% threshold!"
      exit 1
    fi
  else
    exit 1
  fi
fi
'@

$running = podman ps --filter "name=^${ContainerName}$" --format "{{.Names}}"
if ($running -eq $ContainerName) {
    podman exec -w /workspace $ContainerName bash -c $Cmd
} else {
    podman run --rm -v "${WorkspaceDir}:/workspace:Z" -w /workspace $ImageName bash -c $Cmd
}

if ($LASTEXITCODE -ne 0) {
    Write-Error "Coverage check failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}
Write-Host "==> [coverage] Code coverage verified successfully." -ForegroundColor Green
