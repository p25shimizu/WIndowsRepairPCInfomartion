@echo off
setlocal
title Legacy VM Test - v6.20

set "PSEXE=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if not exist "%PSEXE%" (
    echo Windows PowerShell was not found.
    echo Windows XP requires PowerShell 2.0 before this test.
    pause
    exit /b 30
)

set "SCRIPT=%~dp0Legacy_VM_Preflight.ps1"
if not exist "%SCRIPT%" (
    echo Missing: %SCRIPT%
    pause
    exit /b 31
)

"%PSEXE%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"
set "RC=%ERRORLEVEL%"

echo.
echo Preflight ExitCode: %RC%
echo.
echo Next step:
echo Run ..\..\launcher\Run_PCInfo_UserMode.cmd
echo Test both Normal mode and Detailed mode.
echo.
pause
endlocal
exit /b %RC%
