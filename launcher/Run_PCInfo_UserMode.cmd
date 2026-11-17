@echo off
setlocal
title Repair PC Information Logger v6.20

set "PSEXE=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if not exist "%PSEXE%" (
    echo ============================================================
    echo Repair PC Information Logger v6.20
    echo ============================================================
    echo Windows PowerShell was not found.
    echo.
    echo Windows 7 includes PowerShell by default.
    echo Windows XP requires Windows PowerShell 2.0 / WMF 2.0 beforehand.
    echo This tool cannot continue on this PC.
    echo.
    pause
    exit /b 30
)

set "SCRIPTDIR=%~dp0system"
if not exist "%SCRIPTDIR%\Repair_PCInfo_Bootstrap.ps1" set "SCRIPTDIR=%~dp0..\src"
if not exist "%SCRIPTDIR%\Repair_PCInfo_Bootstrap.ps1" set "SCRIPTDIR=%~dp0"

set "RUNLOG=%~dp0Launcher_LastRun.log"
echo ============================================================ > "%RUNLOG%"
echo Repair PC Information Logger v6.20 >> "%RUNLOG%"
echo Start: %date% %time% >> "%RUNLOG%"
echo ============================================================ >> "%RUNLOG%"

"%PSEXE%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SCRIPTDIR%\Repair_PCInfo_Bootstrap.ps1"
set "RC=%ERRORLEVEL%"

echo. >> "%RUNLOG%"
echo ExitCode: %RC% >> "%RUNLOG%"
echo End: %date% %time% >> "%RUNLOG%"

echo.
echo ============================================================
echo Process ended. ExitCode: %RC%
echo ============================================================
echo If it failed, send Launcher_LastRun.log and ImageGeneration_Error.txt.
echo.
pause
endlocal
exit /b %RC%
