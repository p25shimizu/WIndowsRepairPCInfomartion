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

set "DETECTED_OS=Unknown Windows"
set "OSDETECTFILE=%TEMP%\RepairPCInfo_OS_%RANDOM%.txt"
"%PSEXE%" -NoLogo -NoProfile -Command "$o=Get-WmiObject Win32_OperatingSystem; if($o){[Console]::Write($o.Caption)}" > "%OSDETECTFILE%" 2>nul
if exist "%OSDETECTFILE%" (
    set /p "DETECTED_OS="<"%OSDETECTFILE%"
    del /q "%OSDETECTFILE%" >nul 2>&1
)
if "%DETECTED_OS%"=="" set "DETECTED_OS=Unknown Windows"

echo.
echo ============================================================
echo OS confirmation
echo ============================================================
echo Detected OS: %DETECTED_OS%
echo.
set "OSOK="
set /p "OSOK=Is this correct? [Y/N]: "

if /I "%OSOK%"=="Y" goto RUN_AUTO
if /I "%OSOK%"=="YES" goto RUN_AUTO

:MANUAL_OS
echo.
echo Select the actual OS:
echo   1 = Windows XP
echo   2 = Windows Vista
echo   3 = Windows 7
echo   4 = Windows 8 / 8.1
echo   5 = Windows 10
echo   6 = Windows 11
echo   7 = Auto detect
echo.
set "OSSEL="
set /p "OSSEL=Select [1-7]: "

set "REPAIR_PCINFO_FORCE_MODE="
set "REPAIR_PCINFO_FORCE_LABEL="

if "%OSSEL%"=="1" (
    set "REPAIR_PCINFO_FORCE_MODE=LEGACY"
    set "REPAIR_PCINFO_FORCE_LABEL=Windows XP"
    goto RUN_TOOL
)
if "%OSSEL%"=="2" (
    set "REPAIR_PCINFO_FORCE_MODE=LEGACY"
    set "REPAIR_PCINFO_FORCE_LABEL=Windows Vista"
    goto RUN_TOOL
)
if "%OSSEL%"=="3" (
    set "REPAIR_PCINFO_FORCE_MODE=LEGACY"
    set "REPAIR_PCINFO_FORCE_LABEL=Windows 7"
    goto RUN_TOOL
)
if "%OSSEL%"=="4" (
    set "REPAIR_PCINFO_FORCE_MODE=MODERN"
    set "REPAIR_PCINFO_FORCE_LABEL=Windows 8 / 8.1"
    goto RUN_TOOL
)
if "%OSSEL%"=="5" (
    set "REPAIR_PCINFO_FORCE_MODE=MODERN"
    set "REPAIR_PCINFO_FORCE_LABEL=Windows 10"
    goto RUN_TOOL
)
if "%OSSEL%"=="6" (
    set "REPAIR_PCINFO_FORCE_MODE=MODERN"
    set "REPAIR_PCINFO_FORCE_LABEL=Windows 11"
    goto RUN_TOOL
)
if "%OSSEL%"=="7" goto RUN_AUTO

echo Invalid selection.
goto MANUAL_OS

:RUN_AUTO
set "REPAIR_PCINFO_FORCE_MODE="
set "REPAIR_PCINFO_FORCE_LABEL=Auto: %DETECTED_OS%"

:RUN_TOOL
echo DetectedOS=%DETECTED_OS% >> "%RUNLOG%"
echo ForceMode=%REPAIR_PCINFO_FORCE_MODE% >> "%RUNLOG%"
echo ForceLabel=%REPAIR_PCINFO_FORCE_LABEL% >> "%RUNLOG%"

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
if "%REPAIR_PCINFO_TEST_MODE%"=="1" goto NO_PAUSE
pause
:NO_PAUSE
endlocal
exit /b %RC%
