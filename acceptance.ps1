# FocusGuard Root Acceptance Invoker (PowerShell)
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
& "$ScriptDir\scripts\acceptance.ps1" @args
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
