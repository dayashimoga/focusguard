$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

if (Get-Command dart -ErrorAction SilentlyContinue) {
    dart run tool/build_all.dart $args
} else {
    podman exec -w /workspace focusguard-dev dart run tool/build_all.dart $args
}
