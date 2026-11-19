@echo off
setlocal DisableDelayedExpansion
"%SystemRoot%\System32\cmd.exe" /d /c ""%~dp0..\..\src\PCInfo_Legacy_XP.cmd" %*"
exit /b %ERRORLEVEL%
