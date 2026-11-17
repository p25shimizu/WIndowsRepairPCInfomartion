# Repair PC Information Logger v6.20 - Legacy compatibility mode
# Target: Windows XP / Windows 7 with Windows PowerShell 2.0+
# Unsupported OS features are skipped instead of aborting.

$ErrorActionPreference = "SilentlyContinue"
$ToolVersion = "v6.20"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Is-Blank {
    param([string]$Value)
    if ($null -eq $Value) { return $true }
    if ($Value.Trim().Length -eq 0) { return $true }
    return $false
}

function New-Row {
    param([hashtable]$Properties)
    return (New-Object -TypeName PSObject -Property $Properties)
}

function Get-WmiSafe {
    param([string]$Class,[string]$Namespace="root\cimv2",[string]$Filter="")
    try {
        if (Is-Blank $Filter) {
            return @(Get-WmiObject -Class $Class -Namespace $Namespace -ErrorAction SilentlyContinue)
        }
        return @(Get-WmiObject -Class $Class -Namespace $Namespace -Filter $Filter -ErrorAction SilentlyContinue)
    } catch {
        return @()
    }
}

function Show-Terms {
    $termsVersion = "1.2"
    $base = $env:LOCALAPPDATA
    if (Is-Blank $base) { $base = $env:APPDATA }
    if (Is-Blank $base) { $base = $env:TEMP }
    $dir = Join-Path $base "Repair_PCInfo_UserMode"
    $file = Join-Path $dir "TermsAccepted.txt"
    $need = $true

    if (Test-Path $file) {
        try {
            $saved = Get-Content $file
            if ($saved -match "TermsVersion=$termsVersion") { $need = $false }
        } catch {}
    }

    if (-not $need) { return $true }

    Clear-Host
    Write-Host "============================================================"
    Write-Host " Repair PC Information Logger - 利用規約 / 注意事項"
    Write-Host "============================================================"
    Write-Host "本ツールは社内のPC診断・修理支援用です。"
    Write-Host "取得結果は参考情報であり、現物・BIOS・メーカー資料等で最終確認してください。"
    Write-Host "ライセンス情報やS/N等は機密情報として取り扱ってください。"
    Write-Host "LegacyモードではOS/API制約により取得不能な項目があります。"
    Write-Host ""
    $ans = Read-Host "同意しますか？ [Y/N]"
    if ($ans -notmatch "^[Yy]$") { return $false }

    try {
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        @(
            "TermsVersion=$termsVersion"
            "AcceptedAt=$(Get-Date -Format 'yyyy/MM/dd HH:mm:ss')"
            "Accepted=True"
        ) | Out-File -FilePath $file -Encoding UTF8 -Force
    } catch {}
    return $true
}

if (-not (Show-Terms)) { exit 10 }

$CaseNo = Read-Host "案件番号を入力してください（例: 236）"
if (Is-Blank $CaseNo) { Write-Host "案件番号が未入力です。"; Read-Host "Enterキーで終了"; exit 1 }

Write-Host ""
Write-Host "取得モードを選択してください。"
Write-Host "  1 = 通常モード"
Write-Host "  2 = 詳細モード"
$Mode = Read-Host "番号を入力 [1/2]"
if ($Mode -eq "2") { $ModeName = "詳細" } else { $Mode = "1"; $ModeName = "通常" }

$SafeCaseNo = $CaseNo -replace '[\\/:*?"<>|]', '_'
$Desktop = [Environment]::GetFolderPath("Desktop")
$Stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$OutDir = Join-Path $Desktop "No.$SafeCaseNo-PCLog-$Stamp"
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

$MainLog = Join-Path $OutDir "No.$SafeCaseNo-PCInfo.txt"
$SmartLog = Join-Path $OutDir "No.$SafeCaseNo-SMART.txt"
$FirmwareLog = Join-Path $OutDir "No.$SafeCaseNo-FirmwareSecurity.txt"
$DangerLog = Join-Path $OutDir "No.$SafeCaseNo-EventDangerSignals.txt"
$LicenseLog = Join-Path $OutDir "No.$SafeCaseNo-License.txt"
$Spec1 = Join-Path $OutDir "主要スペック1.png"
$Spec2 = Join-Path $OutDir "主要スペック2_SMART.png"
$LicenseImage = Join-Path $OutDir "ライセンス情報.png"
$MsInfoLog = Join-Path $OutDir "msinfo32.txt"
$DxDiagLog = Join-Path $OutDir "dxdiag.txt"
$CaptureTime = Get-Date

function Step {
    param([string]$Text)
    Write-Host ("[{0}] {1}" -f (Get-Date -Format "HH:mm:ss"),$Text)
}

function Add-Line {
    param([string]$Text="")
    $Text | Out-File -FilePath $MainLog -Append -Encoding UTF8
}

function Add-Section {
    param([string]$Title,[scriptblock]$Command)
    Add-Line ""
    Add-Line "============================================================"
    Add-Line "[$Title]"
    Add-Line "============================================================"
    try {
        $r = & $Command
        if ($null -eq $r) { Add-Line "(情報なし / 取得不可)" }
        else { $r | Out-String -Width 400 | Out-File -FilePath $MainLog -Append -Encoding UTF8 }
    } catch {
        Add-Line "取得不可: $($_.Exception.Message)"
    }
}

function Split-Text {
    param([string]$Text,[int]$Length=72)
    $a=@()
    if ($null -eq $Text) { return @("") }
    $r=[string]$Text
    while ($r.Length -gt $Length) {
        $a += $r.Substring(0,$Length)
        $r = $r.Substring($Length)
    }
    $a += $r
    return @($a)
}

function New-LegacyPng {
    param([string]$Path,[string]$Title,[string]$SubTitle,[string[]]$Lines)
    $err = Join-Path $OutDir "ImageGeneration_Error.txt"
    try {
        [void][Reflection.Assembly]::LoadWithPartialName("System.Drawing")
        $bmp = New-Object System.Drawing.Bitmap(2480,3508)
        $bmp.SetResolution(300,300)
        $g=[System.Drawing.Graphics]::FromImage($bmp)
        $g.Clear([System.Drawing.Color]::White)
        $dark=New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(32,37,43))
        $white=New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
        $text=New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(30,30,30))
        $muted=New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(90,90,90))
        $pen=New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(210,210,210),2)
        $fn="MS UI Gothic"
        $tf=New-Object System.Drawing.Font($fn,58,[System.Drawing.FontStyle]::Bold,[System.Drawing.GraphicsUnit]::Pixel)
        $sf=New-Object System.Drawing.Font($fn,30,[System.Drawing.FontStyle]::Regular,[System.Drawing.GraphicsUnit]::Pixel)
        $bf=New-Object System.Drawing.Font($fn,31,[System.Drawing.FontStyle]::Regular,[System.Drawing.GraphicsUnit]::Pixel)
        $hf=New-Object System.Drawing.Font($fn,38,[System.Drawing.FontStyle]::Bold,[System.Drawing.GraphicsUnit]::Pixel)
        $ff=New-Object System.Drawing.Font($fn,23,[System.Drawing.FontStyle]::Regular,[System.Drawing.GraphicsUnit]::Pixel)

        $g.FillRectangle($dark,0,0,2480,250)
        $g.DrawString($Title,$tf,$white,110,55)
        $g.DrawString($SubTitle,$sf,$white,115,155)
        $x=120; $y=300
        foreach ($line in $Lines) {
            if ($y -gt 3270) { $g.DrawString("※ 続きはテキストログを参照",$bf,$text,$x,$y); break }
            if ($line -like "## *") {
                $y += 15
                $g.DrawString($line.Substring(3),$hf,$text,$x,$y)
                $y += 55
                $g.DrawLine($pen,$x,$y,2360,$y)
                $y += 18
            } else {
                $parts = Split-Text -Text $line -Length 72
                foreach ($p in $parts) { $g.DrawString($p,$bf,$text,$x,$y); $y += 43 }
            }
        }
        $footer = "取得日時: {0} / 画像出力: {1} / {2} Legacy" -f $CaptureTime.ToString("yyyy/MM/dd HH:mm:ss"),(Get-Date -Format "yyyy/MM/dd HH:mm:ss"),$ToolVersion
        $g.DrawString($footer,$ff,$muted,120,3420)
        $bmp.Save($Path,[System.Drawing.Imaging.ImageFormat]::Png)
        $tf.Dispose();$sf.Dispose();$bf.Dispose();$hf.Dispose();$ff.Dispose()
        $dark.Dispose();$white.Dispose();$text.Dispose();$muted.Dispose();$pen.Dispose();$g.Dispose();$bmp.Dispose()
        return $true
    } catch {
        @("画像生成に失敗しました。","対象: $Path","エラー: $($_.Exception.Message)") | Out-File $err -Encoding UTF8 -Append
        return $false
    }
}

function Decode-ProductKey {
    param([byte[]]$Bytes)
    if ($null -eq $Bytes -or $Bytes.Length -lt 67) { return $null }
    try {
        $b=New-Object byte[] $Bytes.Length
        [Array]::Copy($Bytes,$b,$Bytes.Length)
        $chars="BCDFGHJKMPQRTVWXY2346789"
        $key=""
        for ($i=24;$i -ge 0;$i--) {
            $cur=0
            for ($j=14;$j -ge 0;$j--) {
                $cur=($cur*256) -bxor $b[$j+52]
                $b[$j+52]=[math]::Floor([double]($cur/24))
                $cur=$cur%24
            }
            $key=$chars.Substring($cur,1)+$key
            if (($i -ne 0) -and (($i%5)-eq 0)) { $key="-"+$key }
        }
        return $key
    } catch { return $null }
}

function Get-FullKey {
    try {
        $cv=Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
        if ($cv.DigitalProductId) { return (Decode-ProductKey -Bytes ([byte[]]$cv.DigitalProductId)) }
    } catch {}
    return $null
}

function Storage-Type {
    param($Disk)
    $i=[string]$Disk.InterfaceType
    if ([string]$Disk.Model -match "(?i)NVMe") { return "NVMe（文字列判定）" }
    if ($i -match "(?i)USB") { return "USB" }
    if ($i -match "(?i)IDE") { return "IDE / SATA互換（要確認）" }
    if ($i -match "(?i)SCSI") { return "SCSI互換 / SATA・RAID等の可能性" }
    if (Is-Blank $i) { return "不明" }
    return $i
}

function Get-AV {
    param([int]$Major)
    $rows=@()
    $spaces=@()
    if ($Major -ge 6) { $spaces += "root\SecurityCenter2" }
    $spaces += "root\SecurityCenter"
    foreach ($ns in $spaces) {
        $avs=Get-WmiSafe -Class "AntiVirusProduct" -Namespace $ns
        foreach ($a in $avs) {
            $rows += New-Row @{Name=$a.displayName;ProductState=$a.productState;ProductUptoDate=$a.productUptoDate;Namespace=$ns}
        }
        if ($rows.Count -gt 0) { break }
    }
    return @($rows)
}

function Get-Office {
    $rows=@()
    $paths=@("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*","HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*")
    foreach ($p in $paths) {
        try {
            $apps=Get-ItemProperty $p | Where-Object {$_.DisplayName -match "(?i)Microsoft (Office|365)" -and $_.DisplayName -notmatch "(?i)Update|Language Pack|Proofing"}
            foreach ($a in $apps) { $rows += New-Row @{Product=$a.DisplayName;Version=$a.DisplayVersion;Publisher=$a.Publisher} }
        } catch {}
    }
    return @($rows | Sort-Object Product,Version -Unique)
}

function Get-License {
    param([int]$Major)
    $rows=@()
    if ($Major -le 5) {
        foreach ($p in (Get-WmiSafe -Class "Win32_WindowsProductActivation")) {
            $s="不明"
            if ($p.ActivationRequired -eq 0) { $s="ライセンス認証済み / 認証不要" }
            elseif ($p.ActivationRequired -eq 1) { $s="ライセンス認証が必要" }
            $rows += New-Row @{Name="Windows Product Activation";LicenseStatus=$s;Channel="Legacy WPA";PartialKey="-"}
        }
    } else {
        foreach ($p in (Get-WmiSafe -Class "SoftwareLicensingProduct")) {
            if ($p.ApplicationID -eq "55c92734-d682-4d71-983e-d6ec3f16059f" -and -not (Is-Blank $p.PartialProductKey)) {
                $map=@{0="未ライセンス";1="ライセンス認証済み";2="初期猶予期間";3="追加猶予期間";4="非正規猶予期間";5="通知モード";6="拡張猶予期間"}
                $s=[string]$p.LicenseStatus
                if ($map.ContainsKey([int]$p.LicenseStatus)) { $s=$map[[int]$p.LicenseStatus] }
                $rows += New-Row @{Name=$p.Name;LicenseStatus=$s;Channel=$p.ProductKeyChannel;PartialKey=$p.PartialProductKey}
            }
        }
    }
    return @($rows)
}

function Get-Danger {
    $rows=@();$after=(Get-Date).AddDays(-30)
    try { $events=@(Get-EventLog -LogName System -After $after -Newest 1000) } catch { $events=@() }
    foreach ($e in $events) {
        $src=[string]$e.Source;$id=[int]$e.EventID;$sev=$null;$cat=$null;$why=$null
        if (($src -match "(?i)BugCheck|Save Dump|System Error") -and (@(1001,1003) -contains $id)) {$sev="重大";$cat="BSOD / System Error";$why="ブルースクリーン/システム停止記録"}
        if ($src -match "(?i)Kernel-Power" -and $id -eq 41) {$sev="重大";$cat="Kernel-Power";$why="異常電源断/クラッシュの可能性"}
        if ($src -match "(?i)WHEA") {$sev="重大";$cat="WHEA";$why="ハードウェアエラー"}
        if ($src -match "(?i)disk|atapi|ntfs|iaStor|volmgr" -and (@(7,9,11,51,55,57,129,153,157) -contains $id)) {$sev="警告";if (@(7,11,55,157) -contains $id){$sev="重大"};$cat="ストレージ";$why="ディスク/FS異常"}
        if ($src -match "(?i)EventLog" -and $id -eq 6008) {$sev="警告";$cat="予期しない終了";$why="正常終了でない"}
        if ($sev) {
            $msg=[string]$e.Message
            if ($msg.Length -gt 800) {$msg=$msg.Substring(0,800)+" ..."}
            $rows += New-Row @{Time=$e.TimeGenerated;Severity=$sev;Category=$cat;Source=$src;EventID=$id;Reason=$why;Message=($msg -replace "|
"," ")}
        }
    }
    return @($rows | Sort-Object Time -Descending)
}

Step "Legacy互換モードで基本情報を取得しています..."
$ver=[Environment]::OSVersion.Version;$major=[int]$ver.Major;$minor=[int]$ver.Minor
$Computer=@(Get-WmiSafe -Class "Win32_ComputerSystem" | Select-Object -First 1)[0]
$Product=@(Get-WmiSafe -Class "Win32_ComputerSystemProduct" | Select-Object -First 1)[0]
$BIOS=@(Get-WmiSafe -Class "Win32_BIOS" | Select-Object -First 1)[0]
$OS=@(Get-WmiSafe -Class "Win32_OperatingSystem" | Select-Object -First 1)[0]
$CPU=@(Get-WmiSafe -Class "Win32_Processor" | Select-Object -First 1)[0]
$RAM=@(Get-WmiSafe -Class "Win32_PhysicalMemory")
$MemArray=@(Get-WmiSafe -Class "Win32_PhysicalMemoryArray")
$Disks=@(Get-WmiSafe -Class "Win32_DiskDrive")
$GPU=@(Get-WmiSafe -Class "Win32_VideoController")
$Volumes=@(Get-WmiSafe -Class "Win32_LogicalDisk" -Filter "DriveType=3")
$Board=@(Get-WmiSafe -Class "Win32_BaseBoard" | Select-Object -First 1)[0]
$AV=@(Get-AV -Major $major)
$Office=@(Get-Office)
$License=@(Get-License -Major $major)
$FullKey=Get-FullKey
if (-not $FullKey) {$FullKey="取得不可"}

$reported=0
if ($MemArray.Count -gt 0) {$sum=($MemArray | Measure-Object -Property MemoryDevices -Sum).Sum;if ($sum){$reported=[int]$sum}}
$used=$RAM.Count;$empty="-"
if ($reported -gt 0){$empty=[Math]::Max(0,$reported-$used)}
$install="要確認"
$loc=(($RAM | ForEach-Object {"$($_.DeviceLocator) $($_.BankLabel)"}) -join " ")
if ($loc -match "(?i)DIMM|SODIMM|SO-DIMM") {$install="交換可能の可能性 / 空きはSMBIOS参考"}

$firmware="不明 / 要確認"
if ($major -le 5) {$firmware="Legacy BIOS想定（XP / 要確認）"}
else {
    try {$fw=Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control" -Name PEFirmwareType;if ([int]$fw.PEFirmwareType -eq 1){$firmware="Legacy BIOS"}elseif([int]$fw.PEFirmwareType -eq 2){$firmware="UEFI"}} catch {}
}
$tpm=@()
if ($major -ge 6){$tpm=@(Get-WmiSafe -Class "Win32_Tpm" -Namespace "root\CIMV2\Security\MicrosoftTpm")}
$tpmText="未検出 / 取得不可"
if ($tpm.Count -gt 0){$tpmText="搭載 / Spec: $($tpm[0].SpecVersion)"}

$avText="未検出";if($AV.Count -gt 0){$avText=($AV | ForEach-Object {$_.Name}) -join " / "}
$officeText="未検出";if($Office.Count -gt 0){$officeText=($Office | ForEach-Object {$_.Product}) -join " / "}
$licText="取得不可";if($License.Count -gt 0){$licText=($License | ForEach-Object {$_.LicenseStatus}) -join " / "}

"============================================================" | Out-File $MainLog -Encoding UTF8
" 修理案件 PC情報ログ $ToolVersion Legacy" | Out-File $MainLog -Append -Encoding UTF8
"============================================================" | Out-File $MainLog -Append -Encoding UTF8
Add-Line "案件番号: No.$CaseNo"
Add-Line "取得モード: $ModeName"
Add-Line "取得日時: $(Get-Date -Format 'yyyy/MM/dd HH:mm:ss')"
Add-Line "PowerShell: $($PSVersionTable.PSVersion)"

Add-Section "本体情報" { New-Row @{Manufacturer=$Computer.Manufacturer;Model=$Computer.Model;ProductName=$Product.Name;SerialNumber=$BIOS.SerialNumber;UUID=$Product.UUID;TotalMemoryGB=[math]::Round($Computer.TotalPhysicalMemory/1GB,2)} | Format-List }
Add-Section "OS" { $OS | Select-Object Caption,Version,BuildNumber,OSArchitecture,ServicePackMajorVersion,ServicePackMinorVersion,InstallDate,LastBootUpTime | Format-List }
Add-Section "CPU" { $CPU | Select-Object Name,Manufacturer,NumberOfCores,NumberOfLogicalProcessors,MaxClockSpeed,CurrentClockSpeed | Format-List }
Add-Section "物理メモリ" { $RAM | Select-Object BankLabel,DeviceLocator,@{N="CapacityGB";E={[math]::Round($_.Capacity/1GB,2)}},Speed,Manufacturer,PartNumber,SerialNumber | Format-Table -AutoSize }
Add-Section "メモリスロット / 増設可否" { "増設可否: $install";"SMBIOS MemoryDevices: $reported";"検出枚数: $used";"空き参考値: $empty";"※現物/メーカー資料で要確認" }
Add-Section "ストレージ" { $Disks | Select-Object Model,SerialNumber,@{N="SizeGB";E={[math]::Round($_.Size/1GB,2)}},InterfaceType,@{N="Connection";E={Storage-Type $_}},Status | Format-Table -AutoSize }
Add-Section "ボリューム" { $Volumes | Select-Object DeviceID,VolumeName,FileSystem,@{N="SizeGB";E={[math]::Round($_.Size/1GB,2)}},@{N="FreeGB";E={[math]::Round($_.FreeSpace/1GB,2)}} | Format-Table -AutoSize }
Add-Section "GPU / ドライバ" { $GPU | Select-Object Name,DriverVersion,DriverDate,VideoModeDescription | Format-Table -AutoSize }
Add-Section "BIOS" { $BIOS | Select-Object Manufacturer,SMBIOSBIOSVersion,Version,SerialNumber,ReleaseDate | Format-List }
Add-Section "マザーボード" { $Board | Select-Object Manufacturer,Product,Version,SerialNumber | Format-List }
Add-Section "PnPデバイス異常" { $bad=@(Get-WmiSafe -Class "Win32_PnPEntity" | Where-Object {$_.ConfigManagerErrorCode -ne 0});if($bad.Count -gt 0){$bad | Select-Object Name,Status,ConfigManagerErrorCode,PNPDeviceID | Format-Table -AutoSize}else{"異常コード付きPnPデバイスなし"} }
Add-Section "ウイルス対策" { if($AV.Count -gt 0){$AV | Format-Table -AutoSize}else{"Security Centerから検出できませんでした"} }
Add-Section "Office" { if($Office.Count -gt 0){$Office | Format-Table -AutoSize}else{"Office未検出"} }
Add-Section "Windowsライセンス" { "完全プロダクトキー: $FullKey";if($License.Count -gt 0){$License | Format-List}else{"ライセンス情報取得不可"} }
Add-Section "Firmware / Secure Boot / TPM" { "Firmware: $firmware";"Secure Boot: OS非対応（XP/7）";"TPM: $tpmText" }

Step "バッテリー情報を取得しています..."
$bat=@(Get-WmiSafe -Class "Win32_Battery")
$bs=@(Get-WmiSafe -Class "BatteryStaticData" -Namespace "root\wmi")
$bf=@(Get-WmiSafe -Class "BatteryFullChargedCapacity" -Namespace "root\wmi")
$bst=@(Get-WmiSafe -Class "BatteryStatus" -Namespace "root\wmi")
$bm="-";$bd="-";$bfull="-";$bcur="-";$bhealth="-"
if($bs.Count -gt 0){if($bs[0].DeviceName){$bm=$bs[0].DeviceName};if($bs[0].DesignedCapacity){$bd="$($bs[0].DesignedCapacity) mWh"}}
if($bm -eq "-" -and $bat.Count -gt 0){$bm=$bat[0].Name}
if($bf.Count -gt 0 -and $bf[0].FullChargedCapacity){$bfull="$($bf[0].FullChargedCapacity) mWh"}
if($bst.Count -gt 0 -and $bst[0].RemainingCapacity){$bcur="$($bst[0].RemainingCapacity) mWh"}
if($bs.Count -gt 0 -and $bf.Count -gt 0 -and $bs[0].DesignedCapacity -gt 0 -and $bf[0].FullChargedCapacity -gt 0){$h=[math]::Round(($bf[0].FullChargedCapacity/$bs[0].DesignedCapacity)*100,1);$bhealth="$h %"}
Add-Section "バッテリー" { "型番: $bm";"設計容量: $bd";"満充電容量: $bfull";"現在容量: $bcur";"寿命目安: $bhealth";"※XP/7ではbatteryreportを生成しません" }

Step "SMART情報を取得しています..."
$smart=@(Get-WmiSafe -Class "MSStorageDriver_FailurePredictStatus" -Namespace "root\wmi")
"SMART / Storage Report $ToolVersion Legacy" | Out-File $SmartLog -Encoding UTF8
foreach($d in $Disks){"$($d.Model) / $([math]::Round($d.Size/1GB,2)) GB / $(Storage-Type $d)" | Out-File $SmartLog -Append -Encoding UTF8}
if($smart.Count -gt 0){$smart | Select-Object InstanceName,PredictFailure,Reason | Format-Table -AutoSize | Out-String -Width 300 | Out-File $SmartLog -Append -Encoding UTF8}else{"SMART FailurePredict取得不可" | Out-File $SmartLog -Append -Encoding UTF8}

Step "イベントログを確認しています..."
$danger=@(Get-Danger)
"Event Viewer Danger Signals $ToolVersion Legacy" | Out-File $DangerLog -Encoding UTF8
if($danger.Count -gt 0){$danger | Format-Table -Wrap | Out-String -Width 500 | Out-File $DangerLog -Append -Encoding UTF8}else{"危険信号として分類したイベントなし" | Out-File $DangerLog -Append -Encoding UTF8}

@("Firmware: $firmware","Secure Boot: OS非対応（XP/7）","TPM: $tpmText") | Out-File $FirmwareLog -Encoding UTF8
"License Report $ToolVersion Legacy" | Out-File $LicenseLog -Encoding UTF8
"完全プロダクトキー: $FullKey" | Out-File $LicenseLog -Append -Encoding UTF8
$License | Format-List | Out-String -Width 300 | Out-File $LicenseLog -Append -Encoding UTF8
"Office: $officeText" | Out-File $LicenseLog -Append -Encoding UTF8

if($Mode -eq "2"){
    Step "詳細モード情報を取得しています..."
    Add-Section "主要ドライバー" { $drv=@(Get-WmiSafe -Class "Win32_PnPSignedDriver");$drv | Where-Object {$_.DeviceName -and $_.DeviceClass -match "DISPLAY|NET|MEDIA|HDC|SCSIAdapter|System|Bluetooth"} | Select-Object DeviceClass,DeviceName,Manufacturer,DriverProviderName,DriverVersion,DriverDate,InfName | Format-Table -AutoSize }
    Add-Section "HotFix" { try{Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 30 | Format-Table -AutoSize}catch{Get-WmiSafe -Class "Win32_QuickFixEngineering" | Select-Object -First 30 | Format-Table -AutoSize} }
    Add-Section "最近のシステムイベント" { try{Get-EventLog -LogName System -After ((Get-Date).AddDays(-3)) -Newest 30 | Select-Object TimeGenerated,EventID,Source,EntryType,Message | Format-Table -Wrap}catch{"取得不可"} }
    try{Start-Process "msinfo32.exe" -ArgumentList "/report \"$MsInfoLog\"" -Wait -WindowStyle Hidden}catch{}
    try{Start-Process "dxdiag.exe" -ArgumentList "/t \"$DxDiagLog\"" -Wait -WindowStyle Hidden}catch{}
}

Step "画像を生成しています..."
$ramGB=0;if($Computer.TotalPhysicalMemory){$ramGB=[math]::Round($Computer.TotalPhysicalMemory/1GB,1)}
$l1=@("## 本体","メーカー: $($Computer.Manufacturer)","モデル: $($Computer.Model)","S/N: $($BIOS.SerialNumber)","OS: $($OS.Caption) $($OS.Version)","","## CPU","CPU: $($CPU.Name)","コア/スレッド: $($CPU.NumberOfCores) / $($CPU.NumberOfLogicalProcessors)","","## メモリ","総容量: $ramGB GB / 搭載枚数: $used","SMBIOSスロット: $reported / 空き参考: $empty","増設可否: $install","","## ストレージ")
foreach($d in $Disks){$l1 += "・$($d.Model) / $([math]::Round($d.Size/1GB,0)) GB / $(Storage-Type $d)"}
$l1 += @("","## GPU")
foreach($g in $GPU){$l1 += "GPU: $($g.Name) / Driver: $($g.DriverVersion)"}
$l1 += @("","## バッテリー","型番: $bm","設計: $bd / 満充電: $bfull / 寿命: $bhealth","","## OS / セキュリティ / Office","Firmware: $firmware","Secure Boot: OS非対応（XP/7）","TPM: $tpmText","ウイルス対策: $avText","Office: $officeText")
$img1=New-LegacyPng -Path $Spec1 -Title "主要スペック 1" -SubTitle "No.$CaseNo / Legacy compatibility" -Lines $l1

$l2=@("## SSD / HDD - SMART")
foreach($d in $Disks){$l2 += "$($d.Model) / $([math]::Round($d.Size/1GB,2)) GB / $(Storage-Type $d)"}
$l2 += @("","## WMI Failure Predict")
if($smart.Count -gt 0){foreach($s in $smart){$l2 += "$($s.InstanceName) / PredictFailure: $($s.PredictFailure)"}}else{$l2 += "取得不可 / 未検出"}
$img2=New-LegacyPng -Path $Spec2 -Title "主要スペック 2 - SMART" -SubTitle "No.$CaseNo / Legacy compatibility" -Lines $l2

$ll=@("## Windows","状態: $licText","完全プロダクトキー: $FullKey","","## Office","インストール: $officeText","認証状態: Legacyでは詳細走査省略","","## 補足","XP: Win32_WindowsProductActivation / Windows 7: SoftwareLicensingProduct")
$imgL=New-LegacyPng -Path $LicenseImage -Title "ライセンス情報" -SubTitle "No.$CaseNo / Legacy compatibility" -Lines $ll

try{
    $c1=Join-Path $ScriptDir "CHANGELOG.txt"
    $c2=Join-Path (Split-Path $ScriptDir -Parent) "CHANGELOG.txt"
    if(Test-Path $c1){Copy-Item $c1 (Join-Path $OutDir "Tool_CHANGELOG.txt") -Force}
    elseif(Test-Path $c2){Copy-Item $c2 (Join-Path $OutDir "Tool_CHANGELOG.txt") -Force}
}catch{}

Write-Host ""
Write-Host "============================================================"
Write-Host " No.$CaseNo PC情報ログ取得完了 - v6.20 Legacy"
Write-Host "============================================================"
Write-Host "対象OS: $($OS.Caption)"
Write-Host "出力先: $OutDir"
Write-Host "※ XP/7では取得不能項目があります。取得不可は故障を意味しません。"
Write-Host ""
Read-Host "Enterキーで終了"
