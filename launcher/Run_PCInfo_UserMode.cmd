@echo off
setlocal DisableDelayedExpansion
if exist "%~dp0system\PCInfo_Launch.cmd" goto packaged
"%SystemRoot%\System32\cmd.exe" /d /c ""%~dp0..\src\PCInfo_Launch.cmd" %*"
exit /b %ERRORLEVEL%

:packaged
"%SystemRoot%\System32\cmd.exe" /d /c ""%~dp0system\PCInfo_Launch.cmd" %*"
exit /b %ERRORLEVEL%
