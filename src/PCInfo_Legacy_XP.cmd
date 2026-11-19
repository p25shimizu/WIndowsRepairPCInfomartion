@echo off
setlocal DisableDelayedExpansion
"%SystemRoot%\System32\cscript.exe" //nologo "%~dp0PCInfo_Legacy_XP_WMI.vbs" %*
exit /b %ERRORLEVEL%
