# Compatibility entry point for earlier automation.
$script = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "PCInfo_Legacy_Win7.ps1"
& $script @args
exit $LASTEXITCODE
