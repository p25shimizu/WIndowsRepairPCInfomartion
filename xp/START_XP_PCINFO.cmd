@echo off
setlocal DisableDelayedExpansion
"%SystemRoot%\System32\cmd.exe" /d /c ""%~dp0system\XP_PCInfo.cmd" %*"
set "RC=%ERRORLEVEL%"
if "%~1"=="" pause
exit /b %RC%
