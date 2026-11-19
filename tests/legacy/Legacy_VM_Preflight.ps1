# Legacy VM Preflight Test for Repair PC Information Logger v6.20
# Target: Windows 7 SP1 with Windows PowerShell 2.0+
# PowerShell 2.0 compatible.

$ErrorActionPreference = "SilentlyContinue"
$ToolVersion = "v6.20"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)
$Desktop = [Environment]::GetFolderPath("Desktop")
$Stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$OutDir = Join-Path $Desktop ("Legacy_VM_Preflight_" + $Stamp)
$Report = Join-Path $OutDir "Legacy_VM_Preflight_Report.txt"
$ImageTest = Join-Path $OutDir "Legacy_VM_SystemDrawing_Test.png"

New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

function Add-Line {
    param([string]$Text="")
    $Text | Out-File -FilePath $Report -Encoding UTF8 -Append
}

function Test-WmiClass {
    param(
        [string]$Class,
        [string]$Namespace="root\cimv2",
        [string]$Label=""
    )
    if ($Label -eq "") { $Label = $Class }

    try {
        $items = @(Get-WmiObject -Class $Class -Namespace $Namespace -ErrorAction SilentlyContinue)
        if ($items.Count -gt 0) {
            Add-Line ("[PASS] {0} : {1} object(s)" -f $Label,$items.Count)
            return $true
        } else {
            Add-Line ("[INFO] {0} : no data / not available" -f $Label)
            return $false
        }
    } catch {
        Add-Line ("[FAIL] {0} : {1}" -f $Label,$_.Exception.Message)
        return $false
    }
}

function Test-CommandPath {
    param([string]$Name)
    try {
        $cmd = Get-Command $Name -ErrorAction SilentlyContinue
        if ($cmd) {
            Add-Line ("[PASS] Command: {0} -> {1}" -f $Name,$cmd.Path)
            return $true
        }
    } catch {}
    Add-Line ("[FAIL] Command not found: {0}" -f $Name)
    return $false
}

"============================================================" | Out-File -FilePath $Report -Encoding UTF8
" Legacy VM Preflight Test - $ToolVersion" | Out-File -FilePath $Report -Encoding UTF8 -Append
"============================================================" | Out-File -FilePath $Report -Encoding UTF8 -Append
Add-Line ("RunAt: {0}" -f (Get-Date -Format "yyyy/MM/dd HH:mm:ss"))
Add-Line ("ComputerName: {0}" -f $env:COMPUTERNAME)
Add-Line ("PowerShellVersion: {0}" -f $PSVersionTable.PSVersion)
Add-Line ("RepositoryRoot: {0}" -f $RepoRoot)
Add-Line ""

$os = @(Get-WmiObject Win32_OperatingSystem -ErrorAction SilentlyContinue | Select-Object -First 1)[0]
if ($os) {
    Add-Line "[OS]"
    Add-Line ("Caption: {0}" -f $os.Caption)
    Add-Line ("Version: {0}" -f $os.Version)
    Add-Line ("Build: {0}" -f $os.BuildNumber)
    Add-Line ("ServicePack: {0}.{1}" -f $os.ServicePackMajorVersion,$os.ServicePackMinorVersion)
    Add-Line ("Architecture: {0}" -f $os.OSArchitecture)
    Add-Line ""
} else {
    Add-Line "[FAIL] Win32_OperatingSystem could not be read."
    Add-Line ""
}

Add-Line "[Required Files]"
$required = @(
    "launcher\Run_PCInfo_UserMode.cmd",
    "src\PCInfo_Launch.cmd",
    "src\PCInfo_Legacy_Win7.ps1"
)
foreach ($rel in $required) {
    $p = Join-Path $RepoRoot $rel
    if (Test-Path $p) {
        Add-Line ("[PASS] {0}" -f $rel)
    } else {
        Add-Line ("[FAIL] Missing: {0}" -f $rel)
    }
}
Add-Line ""

Add-Line "[Commands]"
Test-CommandPath "powershell.exe" | Out-Null
Test-CommandPath "msinfo32.exe" | Out-Null
Test-CommandPath "dxdiag.exe" | Out-Null
Add-Line ""

Add-Line "[Core WMI]"
Test-WmiClass "Win32_ComputerSystem" | Out-Null
Test-WmiClass "Win32_ComputerSystemProduct" | Out-Null
Test-WmiClass "Win32_BIOS" | Out-Null
Test-WmiClass "Win32_OperatingSystem" | Out-Null
Test-WmiClass "Win32_Processor" | Out-Null
Test-WmiClass "Win32_PhysicalMemory" | Out-Null
Test-WmiClass "Win32_PhysicalMemoryArray" | Out-Null
Test-WmiClass "Win32_DiskDrive" | Out-Null
Test-WmiClass "Win32_LogicalDisk" | Out-Null
Test-WmiClass "Win32_VideoController" | Out-Null
Test-WmiClass "Win32_BaseBoard" | Out-Null
Test-WmiClass "Win32_PnPEntity" | Out-Null
Test-WmiClass "Win32_QuickFixEngineering" | Out-Null
Add-Line ""

Add-Line "[Battery / SMART WMI]"
Test-WmiClass "Win32_Battery" | Out-Null
Test-WmiClass "BatteryStaticData" "root\wmi" | Out-Null
Test-WmiClass "BatteryFullChargedCapacity" "root\wmi" | Out-Null
Test-WmiClass "BatteryStatus" "root\wmi" | Out-Null
Test-WmiClass "MSStorageDriver_FailurePredictStatus" "root\wmi" | Out-Null
Add-Line ""

$major = 0
try { $major = [int][Environment]::OSVersion.Version.Major } catch {}

Add-Line "[Security Center]"
if ($major -ge 6) {
    Test-WmiClass "AntiVirusProduct" "root\SecurityCenter2" "AntiVirusProduct SecurityCenter2" | Out-Null
} else {
    Test-WmiClass "AntiVirusProduct" "root\SecurityCenter" "AntiVirusProduct SecurityCenter" | Out-Null
}
Add-Line ""

Add-Line "[Windows Licensing]"
if ($major -le 5) {
    Test-WmiClass "Win32_WindowsProductActivation" "root\cimv2" "XP Windows Product Activation" | Out-Null
} else {
    Test-WmiClass "SoftwareLicensingProduct" "root\cimv2" "Windows Software Licensing" | Out-Null
}
Add-Line ""

Add-Line "[Event Log]"
try {
    $events = @(Get-EventLog -LogName System -Newest 5 -ErrorAction SilentlyContinue)
    Add-Line ("[PASS] System Event Log readable: {0} event(s)" -f $events.Count)
} catch {
    Add-Line ("[FAIL] System Event Log: {0}" -f $_.Exception.Message)
}
Add-Line ""

Add-Line "[System.Drawing]"
try {
    [void][Reflection.Assembly]::LoadWithPartialName("System.Drawing")
    $bmp = New-Object System.Drawing.Bitmap(320,120)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.Clear([System.Drawing.Color]::White)
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Black)
    $font = New-Object System.Drawing.Font("MS UI Gothic",16)
    $g.DrawString("Legacy VM Image Test",$font,$brush,10,35)
    $bmp.Save($ImageTest,[System.Drawing.Imaging.ImageFormat]::Png)
    $font.Dispose()
    $brush.Dispose()
    $g.Dispose()
    $bmp.Dispose()

    if (Test-Path $ImageTest) {
        Add-Line ("[PASS] PNG generated: {0}" -f $ImageTest)
    } else {
        Add-Line "[FAIL] PNG file was not generated."
    }
} catch {
    Add-Line ("[FAIL] System.Drawing: {0}" -f $_.Exception.Message)
}
Add-Line ""

Add-Line "[Result]"
Add-Line "Preflight finished."
Add-Line "INFO does not necessarily mean failure. Battery/SMART/AV data may be absent in a VM."
Add-Line "Next: run launcher\Run_PCInfo_UserMode.cmd and complete Normal + Detailed mode tests."

Write-Host ""
Write-Host "============================================================"
Write-Host " Legacy VM Preflight finished"
Write-Host "============================================================"
Write-Host ("Report: {0}" -f $Report)
Write-Host ("Image test: {0}" -f $ImageTest)
Write-Host ""
