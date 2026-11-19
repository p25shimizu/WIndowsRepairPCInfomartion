@echo off
setlocal DisableDelayedExpansion
title PC Diagnostic Tool v6.20 Internal Preview
set "FINDSTR=%SystemRoot%\System32\findstr.exe"
if /i "%~1"=="/manual" goto manual

ver | "%FINDSTR%" /r /c:" 5\.1\." >nul
if not errorlevel 1 goto xp
ver | "%FINDSTR%" /r /c:" 6\.1\." >nul
if not errorlevel 1 goto win7
ver | "%FINDSTR%" /r /c:" 6\.[23]\." /c:" 10\.0\." >nul
if not errorlevel 1 goto modern

:manual
echo Select Windows version:
echo   1 = Windows XP SP3
echo   2 = Windows 7
echo   3 = Windows 8 / 8.1 / 10 / 11
echo   0 = Cancel
set "PCINFO_CHOICE="
set /p "PCINFO_CHOICE=Select [0-3]: "
if not defined PCINFO_CHOICE exit /b 2
set PCINFO_CHOICE | "%FINDSTR%" /x /c:"PCINFO_CHOICE=1" >nul
if not errorlevel 1 goto xp
set PCINFO_CHOICE | "%FINDSTR%" /x /c:"PCINFO_CHOICE=2" >nul
if not errorlevel 1 goto win7
set PCINFO_CHOICE | "%FINDSTR%" /x /c:"PCINFO_CHOICE=3" >nul
if not errorlevel 1 goto modern
set PCINFO_CHOICE | "%FINDSTR%" /x /c:"PCINFO_CHOICE=0" >nul
if not errorlevel 1 exit /b 2
goto manual

:xp
if "%REPAIR_PCINFO_TEST_MODE%"=="1" (
    echo TEST_SELECTED_MODE=XP
    exit /b 0
)
echo Windows XP - Internal Use Only
"%SystemRoot%\System32\cmd.exe" /d /c ""%~dp0PCInfo_Legacy_XP.cmd""
set "RC=%ERRORLEVEL%"
goto finish

:win7
set "COLLECTOR=PCInfo_Legacy_Win7.ps1"
set "SELECTED=LEGACY"
goto powershell

:modern
set "COLLECTOR=PCInfo_Modern.ps1"
set "SELECTED=MODERN"

:powershell
if "%REPAIR_PCINFO_TEST_MODE%"=="1" (
    echo TEST_SELECTED_MODE=%SELECTED%
    exit /b 0
)
set "PSEXE=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if not exist "%PSEXE%" (
    echo Windows PowerShell was not found.
    set "RC=30"
    goto finish
)
"%PSEXE%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0%COLLECTOR%"
set "RC=%ERRORLEVEL%"
if "%RC%"=="0" exit /b 0

:finish
echo Exit code: %RC%
pause
exit /b %RC%
