# Repair PC Information Logger v6.20 bootstrap
# PowerShell 2.0 compatible. Selects Legacy mode for Windows XP/Vista/7.

$ErrorActionPreference = "SilentlyContinue"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$os = [Environment]::OSVersion.Version
$major = [int]$os.Major
$minor = [int]$os.Minor

$modernScript = Join-Path $ScriptDir "Repair_PCInfo_UserMode.ps1"
$legacyScript = Join-Path $ScriptDir "Repair_PCInfo_Legacy.ps1"

$useLegacy = $false
$forceMode = [string]$env:REPAIR_PCINFO_FORCE_MODE

if ($forceMode -eq "LEGACY") {
    $useLegacy = $true
}
elseif ($forceMode -eq "MODERN") {
    $useLegacy = $false
}
else {
    if ($major -lt 6) { $useLegacy = $true }
    elseif ($major -eq 6 -and $minor -le 1) { $useLegacy = $true }
}


if ([string]$env:REPAIR_PCINFO_TEST_MODE -eq "1") {
    if ($useLegacy) {
        Write-Host "TEST_SELECTED_MODE=LEGACY"
    } else {
        Write-Host "TEST_SELECTED_MODE=MODERN"
    }
    Write-Host ("TEST_OS_VERSION={0}.{1}" -f $major, $minor)
    exit 0
}

if ($useLegacy) {
    Write-Host "============================================================"
    Write-Host " Repair PC Information Logger v6.20"
    Write-Host " Legacy compatibility mode"
    Write-Host "============================================================"
    Write-Host ("Detected OS version: {0}.{1}" -f $major, $minor)
    if (-not [string]::IsNullOrEmpty($env:REPAIR_PCINFO_FORCE_LABEL)) {
        Write-Host ("Manual OS selection: {0}" -f $env:REPAIR_PCINFO_FORCE_LABEL)
    }
    Write-Host "Windows XP / Vista / 7 compatible collector will be used."
    Write-Host ""

    if (-not (Test-Path $legacyScript)) {
        Write-Host "Legacy collector was not found: $legacyScript"
        exit 20
    }

    & $legacyScript
    exit $LASTEXITCODE
}

if (-not (Test-Path $modernScript)) {
    try {
        $candidates = @(Get-ChildItem -Path $RepoRoot -Filter "Repair_PCInfo_UserMode.ps1" -Recurse -ErrorAction SilentlyContinue)
        if ($candidates.Count -gt 0) {
            $modernScript = $candidates[0].FullName
        }
    } catch {}
}

if (-not (Test-Path $modernScript)) {
    Write-Host "Modern collector was not found."
    Write-Host "Expected: $ScriptDir\Repair_PCInfo_UserMode.ps1"
    exit 21
}

& $modernScript
exit $LASTEXITCODE
