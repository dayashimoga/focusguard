$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

if (Get-Command flutter -ErrorAction SilentlyContinue) {
    flutter test --coverage $args
} else {
    podman exec -w /workspace focusguard-dev flutter test --coverage $args
}
