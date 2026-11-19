# Compatibility entry point. The integrated CMD launcher selects the collector.
$script = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "PCInfo_Launch.cmd"
& $script @args
exit $LASTEXITCODE
