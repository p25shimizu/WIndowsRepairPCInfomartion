@echo off
setlocal
title Repair PC Information Logger v6.19
chcp 65001 >nul

set "RUNLOG=%~dp0Launcher_LastRun.log"
echo ============================================================ > "%RUNLOG%"
echo Repair PC Information Logger v6.19 >> "%RUNLOG%"
echo Start: %date% %time% >> "%RUNLOG%"
echo ============================================================ >> "%RUNLOG%"

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Repair_PCInfo_UserMode.ps1" 2>&1 | powershell -NoProfile -Command "$input | Tee-Object -FilePath '%RUNLOG%' -Append"

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
