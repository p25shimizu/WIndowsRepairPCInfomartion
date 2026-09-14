# Repair PC Information Logger v6.19
# Standard-user oriented / no UAC elevation request
# Generates logs + two PNG summary images.

$ErrorActionPreference = "SilentlyContinue"

# ============================================================
# First-run internal use terms
# ============================================================
function Show-FirstRunTerms {
    $termsVersion = "1.1"
    $termsPath = Join-Path $env:LOCALAPPDATA "Repair_PCInfo_UserMode"
    $termsFile = Join-Path $termsPath "TermsAccepted.txt"

    $needAccept = $true
    if (Test-Path $termsFile) {
        try {
            $saved = Get-Content $termsFile -ErrorAction Stop
            if ($saved -match "TermsVersion=$termsVersion") {
                $needAccept = $false
            }
        } catch {}
    }

    if (-not $needAccept) {
        return $true
    }

    Clear-Host
    Write-Host "============================================================"
    Write-Host " Repair PC Information Logger - 利用規約 / 注意事項"
    Write-Host "============================================================"
    Write-Host ""
    Write-Host "本ツールは社内のPC診断・修理支援を目的とした参考情報取得ツールです。"
    Write-Host ""
    Write-Host "【重要】"
    Write-Host "1. 本ツールで取得・判定された情報は参考情報です。"
    Write-Host "   実際の仕様、部品構成、増設可否、交換可否、型番、容量、"
    Write-Host "   ライセンス状態等については、必ず現物・目視・BIOS/UEFI表示・"
    Write-Host "   メーカー公式情報・保守資料等で確認してください。"
    Write-Host ""
    Write-Host "2. 自動判定には誤検出・取得不能・SMBIOS/Windows API上の表記差異が"
    Write-Host "   含まれる可能性があります。本ツールの結果のみを根拠として、"
    Write-Host "   修理判断、部品発注、顧客説明、保証判断を確定しないでください。"
    Write-Host ""
    Write-Host "3. ライセンス情報にはWindows / Office等の認証情報やプロダクトキーが"
    Write-Host "   含まれる場合があります。これらは機密情報として取り扱ってください。"
    Write-Host ""
    Write-Host "4. 本ツールおよび本ツールで生成された情報・画像・ログの利用は"
    Write-Host "   社内業務に限定します。社外への配布、再配布、公開、転載、"
    Write-Host "   個人利用、第三者への提供は禁止します。"
    Write-Host ""
    Write-Host "5. 顧客や社外関係者へ資料を提示する場合は、個人情報・シリアル番号・"
    Write-Host "   プロダクトキー等の機密情報が含まれていないことを事前に確認してください。"
    Write-Host ""
    Write-Host "6. 本ツールの改変版・派生版を社外へ持ち出すことは禁止します。"
    Write-Host "   社内での改変・更新は、管理担当者の承認のもとで実施してください。"
    Write-Host ""
    Write-Host "7. 本ツールの利用者は、出力結果をそのまま最終判断とせず、"
    Write-Host "   業務上必要な追加確認を行ったうえで利用してください。"
    Write-Host ""
    Write-Host "============================================================"
    Write-Host "上記内容を理解し、社内利用規約に同意する場合のみ続行してください。"
    Write-Host "============================================================"
    Write-Host ""

    $answer = Read-Host "同意しますか？ [Y/N]"
    if ($answer -notmatch '^[Yy]$') {
        Write-Host ""
        Write-Host "同意されなかったため終了します。"
        return $false
    }

    try {
        if (-not (Test-Path $termsPath)) {
            New-Item -ItemType Directory -Path $termsPath -Force | Out-Null
        }
        @(
            "TermsVersion=$termsVersion"
            "AcceptedAt=$(Get-Date -Format 'yyyy/MM/dd HH:mm:ss')"
            "ComputerName=$env:COMPUTERNAME"
            "UserName=$env:USERNAME"
        ) | Out-File -FilePath $termsFile -Encoding UTF8 -Force
    } catch {
        Write-Host ""
        Write-Host "※ 同意履歴の保存に失敗しましたが、今回の実行は続行します。"
    }

    return $true
}

if (-not (Show-FirstRunTerms)) {
    Read-Host "Enterキーで終了"
    exit 10
}


# ============================================================
# Input
# ============================================================
$CaseNo = Read-Host "案件番号を入力してください（例: 236）"
if ([string]::IsNullOrWhiteSpace($CaseNo)) {
    Write-Host "案件番号が未入力です。終了します。"
    Read-Host "Enterキーで終了"
    exit 1
}

Write-Host ""
Write-Host "取得モードを選択してください。"
Write-Host "  1 = 通常モード"
Write-Host "  2 = 詳細モード"
$Mode = Read-Host "番号を入力 [1/2]"

if ($Mode -eq "2") {
    $ModeName = "詳細"
} else {
    $Mode = "1"
    $ModeName = "通常"
}

$SafeCaseNo = $CaseNo -replace '[\\/:*?"<>|]', '_'
$Desktop = [Environment]::GetFolderPath("Desktop")
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$OutDir = Join-Path $Desktop "No.$SafeCaseNo-PCLog-$Timestamp"

$MainLog    = Join-Path $OutDir "No.$SafeCaseNo-PCInfo.txt"
$SmartLog   = Join-Path $OutDir "No.$SafeCaseNo-SMART.txt"
$MsInfoLog  = Join-Path $OutDir "msinfo32.txt"
$DxDiagLog  = Join-Path $OutDir "dxdiag.txt"
$BatteryLog = Join-Path $OutDir "battery-report.html"
$SpecImage1 = Join-Path $OutDir "主要スペック1.png"
$SpecImage2 = Join-Path $OutDir "主要スペック2_SMART.png"
$LicenseLog = Join-Path $OutDir "No.$SafeCaseNo-License.txt"
$LicenseImage = Join-Path $OutDir "ライセンス情報.png"
$CaptureTimestamp = Get-Date
$FirmwareLog = Join-Path $OutDir "No.$SafeCaseNo-FirmwareSecurity.txt"
$DangerEventLog = Join-Path $OutDir "No.$SafeCaseNo-EventDangerSignals.txt"
$ChangeLogOut = Join-Path $OutDir "Tool_CHANGELOG.txt"

New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

# ============================================================
# Helpers
# ============================================================
function Show-Step {
    param([string]$Text)
    Write-Host ("[{0}] {1}" -f (Get-Date -Format "HH:mm:ss"), $Text)
}

function Add-Line {
    param([string]$Text = "")
    $Text | Out-File -FilePath $MainLog -Append -Encoding UTF8
}

function Add-Section {
    param(
        [string]$Title,
        [scriptblock]$Command
    )

    Add-Line
    Add-Line "============================================================"
    Add-Line "[$Title]"
    Add-Line "============================================================"

    try {
        $result = & $Command
        if ($null -eq $result) {
            Add-Line "(情報なし / 取得不可)"
        } else {
            $result | Out-String -Width 400 |
                Out-File -FilePath $MainLog -Append -Encoding UTF8
        }
    } catch {
        Add-Line "取得不可: $($_.Exception.Message)"
    }
}

function Format-Value {
    param($Value, [string]$Suffix = "")
    if ($null -eq $Value -or "$Value" -eq "") {
        return "-"
    }
    return "$Value$Suffix"
}

function New-InfoPng {
    param(
        [string]$Path,
        [string]$Title,
        [string]$SubTitle,
        [string[]]$Lines,
        [datetime]$CaptureTime
    )

    $errorLog = Join-Path (Split-Path $Path -Parent) "ImageGeneration_Error.txt"

    try {
        Add-Type -AssemblyName System.Drawing

        # A4 portrait, 300 dpi
        $width = 2480
        $height = 3508
        $bmp = New-Object System.Drawing.Bitmap($width, $height)
        $bmp.SetResolution(300, 300)

        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.Clear([System.Drawing.Color]::White)

        $headerBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(32,37,43))
        $whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
        $textBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(30,30,30))
        $mutedBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(95,95,95))
        $linePen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(210,210,210), 2)

        $titleFont = New-Object System.Drawing.Font("Yu Gothic UI", 58, ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel))
        $subFont = New-Object System.Drawing.Font("Yu Gothic UI", 30, ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel))
        $bodyFont = New-Object System.Drawing.Font("Yu Gothic UI", 34, ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel))
        $sectionFont = New-Object System.Drawing.Font("Yu Gothic UI", 40, ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel))
        $footerFont = New-Object System.Drawing.Font("Yu Gothic UI", 24, ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel))

        $g.FillRectangle($headerBrush, 0, 0, $width, 175)
        $g.DrawString($Title, $titleFont, $whiteBrush, 90, 28)
        $g.DrawString($SubTitle, $subFont, $whiteBrush, 95, 108)

        $x = 110
        $y = 225
        $maxY = 3380
        $bodyStep = 52

        foreach ($line in $Lines) {
            if ($y -ge $maxY) {
                $g.DrawString("※ 続きはTXTログをご確認ください。", $footerFont, $mutedBrush, $x, 3360)
                break
            }

            if ([string]::IsNullOrWhiteSpace($line)) {
                $y += 24
                continue
            }

            if ($line -match '^##\s*(.+)$') {
                $section = $Matches[1]
                $g.DrawString($section, $sectionFont, $textBrush, $x, $y)
                $y += 52
                $g.DrawLine($linePen, $x, $y, 2370, $y)
                $y += 18
                continue
            }

            $s = [string]$line
            $maxChars = 72
            while ($s.Length -gt $maxChars) {
                $cut = $maxChars
                for ($i = $maxChars; $i -ge 45; $i--) {
                    if ($s[$i-1] -eq ' ' -or $s[$i-1] -eq '/' -or $s[$i-1] -eq '、') {
                        $cut = $i
                        break
                    }
                }
                $part = $s.Substring(0, $cut).Trim()
                $g.DrawString($part, $bodyFont, $textBrush, $x + 20, $y)
                $y += $bodyStep
                $s = $s.Substring($cut).Trim()
                if ($y -ge $maxY) { break }
            }

            if ($y -lt $maxY -and $s.Length -gt 0) {
                $g.DrawString($s, $bodyFont, $textBrush, $x + 20, $y)
                $y += $bodyStep
            }
        }

        $outputTime = Get-Date
        $captureText = if ($CaptureTime) { $CaptureTime.ToString("yyyy/MM/dd HH:mm:ss") } else { "-" }
        $outputText = $outputTime.ToString("yyyy/MM/dd HH:mm:ss")
        $footer = "取得日時: $captureText / 画像出力: $outputText / Repair PC Information Logger v6.19"
        $g.DrawString($footer, $footerFont, $mutedBrush, 110, 3430)

        $bmp.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)

        $titleFont.Dispose()
        $subFont.Dispose()
        $bodyFont.Dispose()
        $sectionFont.Dispose()
        $footerFont.Dispose()
        $headerBrush.Dispose()
        $whiteBrush.Dispose()
        $textBrush.Dispose()
        $mutedBrush.Dispose()
        $linePen.Dispose()
        $g.Dispose()
        $bmp.Dispose()

        return $true
    }
    catch {
        @(
            "画像生成に失敗しました。"
            "対象: $Path"
            "日時: $(Get-Date -Format 'yyyy/MM/dd HH:mm:ss')"
            "エラー: $($_.Exception.Message)"
            "種類: $($_.Exception.GetType().FullName)"
            "位置: $($_.InvocationInfo.PositionMessage)"
        ) | Out-File -FilePath $errorLog -Encoding UTF8 -Append
        return $false
    }
}

function Get-StorageConnectionType {
    param(
        $Disk,
        $PhysicalDisk,
        $Controllers
    )

    $controllerText = (($Controllers | ForEach-Object { $_.DeviceName }) -join ' | ')

    if ($PhysicalDisk -and "$($PhysicalDisk.BusType)" -eq "NVMe") {
        return "NVMe"
    }

    if ($controllerText -match '(?i)\bVMD\b|Rapid Storage|Intel.*RST|RAID') {
        return "RAID / Intel RST / VMD"
    }

    if ($controllerText -match '(?i)AHCI') {
        return "AHCI"
    }

    if ($PhysicalDisk) {
        switch ("$($PhysicalDisk.BusType)") {
            "SATA" { return "SATA / AHCI系" }
            "ATA"  { return "ATA / AHCI系" }
            "RAID" { return "RAID" }
            "SAS"  { return "SAS" }
            "USB"  { return "USB" }
            "NVMe" { return "NVMe" }
            "SCSI" { return "ストレージコントローラー経由" }
        }
    }

    if ($Disk -and "$($Disk.InterfaceType)" -match '(?i)IDE') {
        return "AHCI / IDE互換"
    }

    if ($Disk -and "$($Disk.InterfaceType)" -match '(?i)USB') {
        return "USB"
    }

    return "不明"
}

function Test-Optane {
    param(
        $Disk,
        $PhysicalDisk,
        $Controllers
    )

    $allText = "$($Disk.Model) $($PhysicalDisk.FriendlyName) " +
        (($Controllers | ForEach-Object { $_.DeviceName }) -join ' ')

    if ($allText -match '(?i)Optane') {
        return $true
    }

    return $false
}


function Get-MemoryInstallability {
    param(
        $Computer,
        $Product,
        $RAM,
        $MemArray
    )

    $manufacturer = "$($Computer.Manufacturer)"
    $model = "$($Computer.Model) $($Product.Name)"
    $locators = (($RAM | ForEach-Object { "$($_.DeviceLocator) $($_.BankLabel)" }) -join " ")

    # Strong indicators of soldered/onboard memory
    $onboardText = $locators -match '(?i)onboard|on-board|soldered|solder|system board|motherboard'

    # Known notebook families that are commonly/all-soldered.
    # Keep this conservative: only families where user-replaceable DIMM slots are generally absent.
    $knownSolderedModel = $false

    if ($manufacturer -match '(?i)lenovo') {
        if ($model -match '(?i)ThinkPad\s+X1\s+(Carbon|Yoga|Nano|Fold)') {
            $knownSolderedModel = $true
        }
    }

    if ($manufacturer -match '(?i)Microsoft') {
        if ($model -match '(?i)Surface') {
            $knownSolderedModel = $true
        }
    }

    # SMBIOS may report MemoryDevices even when memory is soldered.
    # Do NOT treat MemoryDevices alone as a physical SO-DIMM slot count.
    $reported = 0
    if ($MemArray.Count -gt 0) {
        $sum = ($MemArray | Measure-Object -Property MemoryDevices -Sum).Sum
        if ($sum) { $reported = [int]$sum }
    }

    $detectedModules = $RAM.Count

    if ($knownSolderedModel -or $onboardText) {
        return [PSCustomObject]@{
            Installable         = "不可"
            Reason              = "オンボード（基板直付け）メモリと判定"
            PhysicalSlots       = 0
            SMBIOSMemoryDevices = $reported
            DetectedModules     = $detectedModules
            Confidence          = "高"
        }
    }

    # If SMBIOS explicitly reports zero memory devices and RAM is present,
    # this strongly suggests onboard memory.
    if ($reported -eq 0 -and $detectedModules -gt 0) {
        return [PSCustomObject]@{
            Installable         = "不可の可能性が高い"
            Reason              = "RAMは検出されるがSMBIOS上のMemoryDevicesが0"
            PhysicalSlots       = 0
            SMBIOSMemoryDevices = $reported
            DetectedModules     = $detectedModules
            Confidence          = "中"
        }
    }

    # If we can detect standard DIMM/SODIMM-style locator names, treat as replaceable.
    if ($locators -match '(?i)DIMM|SODIMM|SO-DIMM|Channel[A-Z]') {
        $empty = [Math]::Max(0, $reported - $detectedModules)
        return [PSCustomObject]@{
            Installable         = if ($empty -gt 0) { "可能" } else { "交換は可能 / 空きなし" }
            Reason              = "DIMM/SO-DIMMスロット形式を検出"
            PhysicalSlots       = if ($reported -gt 0) { $reported } else { $detectedModules }
            SMBIOSMemoryDevices = $reported
            DetectedModules     = $detectedModules
            Confidence          = "中"
        }
    }

    # Otherwise avoid lying. SMBIOS MemoryDevices is not enough to prove a replaceable slot exists.
    return [PSCustomObject]@{
        Installable         = "要確認"
        Reason              = "SMBIOS情報だけでは物理スロット有無を確定できません"
        PhysicalSlots       = "-"
        SMBIOSMemoryDevices = $reported
        DetectedModules     = $detectedModules
        Confidence          = "低"
    }
}



function Get-AntivirusStatus {
    $rows = @()
    try {
        $avs = Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntivirusProduct
        foreach ($av in $avs) {
            $rows += [PSCustomObject]@{
                Name      = $av.displayName
                Path      = $av.pathToSignedProductExe
                State     = ('0x{0:X}' -f $av.productState)
            }
        }
    } catch {}
    return @($rows)
}

function Get-ApproxPassMarkScore {
    param([string]$CpuName)

    $map = @{
        'i5-1334U' = 13500
        'i5-1335U' = 13700
        'i5-1340P' = 17400
        'i3-1305U' = 10400
        'i7-1360P' = 19800
        'i7-1355U' = 16800
    }

    foreach ($k in $map.Keys) {
        if ($CpuName -match [regex]::Escape($k)) {
            return $map[$k]
        }
    }
    return $null
}


function Get-AtaSmartAttributes {
    $rows = @()

    try {
        $predictData = @(Get-CimInstance -Namespace root\wmi -ClassName MSStorageDriver_FailurePredictData)
        $thresholds  = @(Get-CimInstance -Namespace root\wmi -ClassName MSStorageDriver_FailurePredictThresholds)

        foreach ($item in $predictData) {
            $bytes = [byte[]]$item.VendorSpecific
            if (-not $bytes -or $bytes.Length -lt 362) { continue }

            $thresholdItem = $thresholds |
                Where-Object { $_.InstanceName -eq $item.InstanceName } |
                Select-Object -First 1

            $thresholdBytes = if ($thresholdItem) { [byte[]]$thresholdItem.VendorSpecific } else { $null }

            for ($offset = 2; $offset -le 350; $offset += 12) {
                $id = [int]$bytes[$offset]
                if ($id -eq 0) { continue }

                $flags = [int]$bytes[$offset + 1] + ([int]$bytes[$offset + 2] -shl 8)
                $current = [int]$bytes[$offset + 3]
                $worst   = [int]$bytes[$offset + 4]

                [UInt64]$raw = 0
                for ($j = 0; $j -lt 6; $j++) {
                    $raw += ([UInt64]$bytes[$offset + 5 + $j] -shl (8 * $j))
                }

                $threshold = $null
                if ($thresholdBytes -and $thresholdBytes.Length -gt ($offset + 3)) {
                    if ([int]$thresholdBytes[$offset] -eq $id) {
                        $threshold = [int]$thresholdBytes[$offset + 3]
                    }
                }

                $nameMap = @{
                    1   = "Read Error Rate"
                    5   = "Reallocated Sectors Count"
                    7   = "Seek Error Rate"
                    9   = "Power-On Hours"
                    10  = "Spin Retry Count"
                    12  = "Power Cycle Count"
                    171 = "Program Fail Count"
                    172 = "Erase Fail Count"
                    173 = "Wear Leveling Count"
                    174 = "Unexpected Power Loss Count"
                    175 = "Program Fail Count"
                    177 = "Wear Range Delta"
                    179 = "Used Reserved Block Count"
                    181 = "Program Fail Count"
                    182 = "Erase Fail Count"
                    183 = "Runtime Bad Block"
                    184 = "End-to-End Error"
                    187 = "Reported Uncorrectable Errors"
                    188 = "Command Timeout"
                    190 = "Airflow Temperature"
                    194 = "Temperature"
                    195 = "ECC Error Rate"
                    196 = "Reallocation Event Count"
                    197 = "Current Pending Sector Count"
                    198 = "Offline Uncorrectable Sector Count"
                    199 = "UDMA CRC Error Count"
                    202 = "Percent Lifetime Remaining"
                    206 = "Write Error Rate"
                    231 = "SSD Life Left"
                    232 = "Available Reserved Space"
                    233 = "Media Wearout Indicator"
                    241 = "Total LBAs Written"
                    242 = "Total LBAs Read"
                }

                $name = if ($nameMap.ContainsKey($id)) { $nameMap[$id] } else { "SMART Attribute $id" }

                $rows += [PSCustomObject]@{
                    InstanceName = $item.InstanceName
                    ID           = $id
                    Name         = $name
                    Current      = $current
                    Worst        = $worst
                    Threshold    = $threshold
                    RawValue     = $raw
                    Flags        = ('0x{0:X4}' -f $flags)
                }
            }
        }
    } catch {}

    return @($rows)
}


function Get-FullWindowsProductKey {
    $key = $null

    # OEM OA3 key embedded in UEFI/firmware.
    try {
        $svc = Get-CimInstance SoftwareLicensingService
        if ($svc.OA3xOriginalProductKey) {
            $key = $svc.OA3xOriginalProductKey
        }
    } catch {}

    if (-not $key) {
        try {
            $reg = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform"
            if ($reg.BackupProductKeyDefault) {
                $key = $reg.BackupProductKeyDefault
            }
        } catch {}
    }

    return $key
}

function Get-WindowsLicenseInfo {
    $rows = @()
    try {
        $products = Get-CimInstance SoftwareLicensingProduct |
            Where-Object {
                $_.ApplicationID -eq '55c92734-d682-4d71-983e-d6ec3f16059f' -and
                $_.PartialProductKey
            }

        foreach ($p in $products) {
            $statusMap = @{
                0 = "未ライセンス"
                1 = "ライセンス認証済み"
                2 = "初期猶予期間"
                3 = "追加猶予期間"
                4 = "非正規猶予期間"
                5 = "通知モード"
                6 = "拡張猶予期間"
            }

            $rows += [PSCustomObject]@{
                Name              = $p.Name
                Description       = $p.Description
                LicenseStatus     = if ($statusMap.ContainsKey([int]$p.LicenseStatus)) { $statusMap[[int]$p.LicenseStatus] } else { "$($p.LicenseStatus)" }
                PartialProductKey = $p.PartialProductKey
                ProductKeyChannel = $p.ProductKeyChannel
                GraceMinutes      = $p.GracePeriodRemaining
            }
        }
    } catch {}
    return @($rows)
}

function Get-OfficeLicenseInfo {
    # v6.19: Office licensing scan disabled for speed.
    # Only detect Office/Microsoft 365 installation from registry.
    # Do NOT enumerate SoftwareLicensingProduct, run ospp.vbs, cscript, or search for keys.
    $results = @()

    $c2rPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun\Configuration"
    )

    foreach ($path in $c2rPaths) {
        try {
            if (Test-Path $path) {
                $cfg = Get-ItemProperty -Path $path -ErrorAction Stop

                $product = $cfg.ProductReleaseIds
                if (-not $product) { $product = "Microsoft Office / Microsoft 365" }

                $version = $cfg.VersionToReport
                if (-not $version) { $version = $cfg.ClientVersionToReport }
                if (-not $version) { $version = "-" }

                $platform = $cfg.Platform
                if (-not $platform) { $platform = "-" }

                $results += [PSCustomObject]@{
                    Name              = [string]$product
                    Description       = "Registry install detection only"
                    LicenseStatus     = "認証走査省略"
                    ProductKeyChannel = "-"
                    PartialProductKey = "-"
                    Version           = [string]$version
                    Platform          = [string]$platform
                }
                return @($results)
            }
        } catch {}
    }

    try {
        $apps = Get-ItemProperty `
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*", `
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" `
            -ErrorAction SilentlyContinue |
            Where-Object {
                $_.DisplayName -match '(?i)Microsoft 365|Microsoft Office|Office LTSC|Office Professional|Office Home|Office Standard'
            } |
            Select-Object -First 3

        foreach ($app in $apps) {
            $results += [PSCustomObject]@{
                Name              = [string]$app.DisplayName
                Description       = "Registry install detection only"
                LicenseStatus     = "認証走査省略"
                ProductKeyChannel = "-"
                PartialProductKey = "-"
                Version           = [string]$app.DisplayVersion
                Platform          = "-"
            }
        }
    } catch {}

    return @($results)
}

function Get-FirmwareSecurityInfo {
    $firmwareType = "不明"
    try {
        $fw = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control" -Name PEFirmwareType
        switch ([int]$fw.PEFirmwareType) {
            1 { $firmwareType = "Legacy BIOS" }
            2 { $firmwareType = "UEFI" }
            default { $firmwareType = "不明" }
        }
    } catch {}

    $secureBoot = "不明 / 非対応"
    try {
        $sb = Confirm-SecureBootUEFI
        if ($sb -eq $true) {
            $secureBoot = "有効"
        } else {
            $secureBoot = "無効"
        }
    } catch {
        if ($firmwareType -eq "Legacy BIOS") {
            $secureBoot = "非対応（Legacy BIOS）"
        }
    }

    $tpmPresent = $false
    $tpmReady = $false
    $tpmEnabled = $false
    $tpmActivated = $false
    $tpmSpec = "-"
    $tpmManufacturer = "-"

    try {
        $tpm = Get-Tpm
        if ($tpm) {
            $tpmPresent = $tpm.TpmPresent
            $tpmReady = $tpm.TpmReady
            $tpmEnabled = $tpm.TpmEnabled
            $tpmActivated = $tpm.TpmActivated
            if ($tpm.ManufacturerIdTxt) {
                $tpmManufacturer = $tpm.ManufacturerIdTxt
            }
        }
    } catch {}

    try {
        $tpmWmi = Get-CimInstance -Namespace root\CIMV2\Security\MicrosoftTpm -ClassName Win32_Tpm
        if ($tpmWmi) {
            if ($tpmWmi.SpecVersion) {
                $tpmSpec = $tpmWmi.SpecVersion
            }
            if ($tpmWmi.ManufacturerIdTxt) {
                $tpmManufacturer = $tpmWmi.ManufacturerIdTxt
            }
        }
    } catch {}

    $tpm2 = $false
    if ($tpmSpec -match '2\.0') { $tpm2 = $true }

    $win11FirmwareReq = if ($firmwareType -eq "UEFI") { "満たす" } else { "未達 / 要確認" }
    $win11SecureBootReq = if ($firmwareType -eq "UEFI") {
        if ($secureBoot -eq "有効") { "満たす" } else { "Secure Boot対応は必要（現在無効の可能性）" }
    } else {
        "未達 / 要確認"
    }
    $win11TpmReq = if ($tpmPresent -and $tpm2) { "満たす（TPM 2.0）" } else { "未達 / 要確認" }

    return [PSCustomObject]@{
        FirmwareType            = $firmwareType
        SecureBoot              = $secureBoot
        TpmPresent              = $tpmPresent
        TpmReady                = $tpmReady
        TpmEnabled              = $tpmEnabled
        TpmActivated            = $tpmActivated
        TpmSpecVersion          = $tpmSpec
        TpmManufacturer         = $tpmManufacturer
        Windows11_UEFI_Req      = $win11FirmwareReq
        Windows11_SecureBootReq = $win11SecureBootReq
        Windows11_TPM_Req       = $win11TpmReq
    }
}


function Get-EventDangerSignals {
    param(
        [int]$Days = 30,
        [int]$MaxEvents = 500
    )

    $start = (Get-Date).AddDays(-$Days)
    $signals = @()

    try {
        $events = Get-WinEvent -FilterHashtable @{
            LogName   = 'System'
            StartTime = $start
        } -MaxEvents $MaxEvents

        foreach ($e in $events) {
            $provider = [string]$e.ProviderName
            $id = [int]$e.Id
            $msg = [string]$e.Message

            $severity = $null
            $category = $null
            $reason = $null

            # BSOD / BugCheck
            if ($provider -match '(?i)BugCheck' -or $id -eq 1001 -or $msg -match '(?i)bugcheck|バグチェック') {
                $severity = "重大"
                $category = "BSOD / BugCheck"
                $reason = "Windowsがバグチェック（ブルースクリーン）を記録"

                if ($msg -match '(?i)0x000000ef|0xEF|CRITICAL_PROCESS_DIED') {
                    $category = "CRITICAL_PROCESS_DIED"
                    $reason = "停止コード 0xEF / CRITICAL_PROCESS_DIED を検出"
                }
            }

            # Unexpected reboot / power loss
            if ($provider -match '(?i)Microsoft-Windows-Kernel-Power' -and $id -eq 41) {
                $severity = "重大"
                $category = "Kernel-Power"
                $reason = "正常終了前の再起動・電源断・クラッシュの可能性"
            }

            # WHEA hardware errors
            if ($provider -match '(?i)WHEA-Logger') {
                if ($id -in 18,20,46,47) {
                    $severity = "重大"
                    $category = "WHEA ハードウェアエラー"
                    $reason = "CPU / メモリ / PCIe等のハードウェアエラー報告"
                }
                elseif ($id -in 17,19) {
                    $severity = "警告"
                    $category = "WHEA 修正済みハードウェアエラー"
                    $reason = "修正可能なハードウェアエラーを検出"
                }
            }

            # Storage / disk controller danger signals
            if (
                $provider -match '(?i)disk|storahci|stornvme|iaStor|Ntfs|volmgr' -and
                $id -in 7,11,51,55,57,129,140,153,157,161
            ) {
                $severity = if ($id -in 7,11,55,157,161) { "重大" } else { "警告" }
                $category = "ストレージ / ファイルシステム"
                $reason = "ディスク、ストレージコントローラー、NTFS等の異常イベント"
            }

            # Unexpected shutdown
            if ($provider -match '(?i)EventLog' -and $id -eq 6008) {
                $severity = "警告"
                $category = "予期しないシャットダウン"
                $reason = "前回のWindows終了が正常でなかった"
            }

            # Display driver recovery / GPU trouble
            if ($provider -match '(?i)Display|nvlddmkm|amdkmdag|igfx' -and $id -in 4101,14,13) {
                $severity = "警告"
                $category = "GPU / ディスプレイドライバ"
                $reason = "GPUドライバ停止・回復・GPU関連異常の可能性"
            }

            if ($severity) {
                $cleanMessage = ($msg -replace "`r|`n", " ")
                if ($cleanMessage.Length -gt 1200) {
                    $cleanMessage = $cleanMessage.Substring(0,1200) + " ..."
                }

                $signals += [PSCustomObject]@{
                    TimeCreated = $e.TimeCreated
                    Severity    = $severity
                    Category    = $category
                    Provider    = $provider
                    EventID     = $id
                    Reason      = $reason
                    Message     = $cleanMessage
                }
            }
        }
    } catch {}

    # Also inspect Application Error / WER events for repeated app/system process crashes.
    try {
        $appEvents = Get-WinEvent -FilterHashtable @{
            LogName   = 'Application'
            StartTime = $start
        } -MaxEvents $MaxEvents

        foreach ($e in $appEvents) {
            $provider = [string]$e.ProviderName
            $id = [int]$e.Id
            $msg = [string]$e.Message

            if (
                ($provider -match '(?i)Application Error|Windows Error Reporting' -and $id -in 1000,1001) -and
                $msg -match '(?i)csrss\.exe|wininit\.exe|winlogon\.exe|services\.exe|lsass\.exe|smss\.exe'
            ) {
                $cleanMessage = ($msg -replace "`r|`n", " ")
                if ($cleanMessage.Length -gt 1200) {
                    $cleanMessage = $cleanMessage.Substring(0,1200) + " ..."
                }

                $signals += [PSCustomObject]@{
                    TimeCreated = $e.TimeCreated
                    Severity    = "重大"
                    Category    = "重要システムプロセス異常"
                    Provider    = $provider
                    EventID     = $id
                    Reason      = "Windows重要プロセスのクラッシュ/障害記録"
                    Message     = $cleanMessage
                }
            }
        }
    } catch {}

    return @($signals | Sort-Object TimeCreated -Descending)
}

# ============================================================
# Privilege status
# ============================================================
$isAdmin = $false
try {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
} catch {}

function Convert-DellServiceTagToExpressCode {
    param([string]$ServiceTag)

    if ([string]::IsNullOrWhiteSpace($ServiceTag)) {
        return "-"
    }

    $tag = $ServiceTag.Trim().ToUpperInvariant()
    [decimal]$value = 0

    foreach ($ch in $tag.ToCharArray()) {
        [int]$digit = -1

        if ($ch -ge '0' -and $ch -le '9') {
            $digit = [int]$ch - [int][char]'0'
        }
        elseif ($ch -ge 'A' -and $ch -le 'Z') {
            $digit = 10 + ([int]$ch - [int][char]'A')
        }
        else {
            return "-"
        }

        $value = ($value * 36) + $digit
    }

    return $value.ToString("0")
}

# ============================================================
# Base information
# ============================================================
Show-Step "基本情報を取得しています..."

$Computer = Get-CimInstance Win32_ComputerSystem
$Product  = Get-CimInstance Win32_ComputerSystemProduct
$BIOS     = Get-CimInstance Win32_BIOS
$OS       = Get-CimInstance Win32_OperatingSystem
$CPU      = Get-CimInstance Win32_Processor
$RAM      = @(Get-CimInstance Win32_PhysicalMemory)
$MemArray = @(Get-CimInstance Win32_PhysicalMemoryArray)
$Disks    = @(Get-CimInstance Win32_DiskDrive)
$GPU      = @(Get-CimInstance Win32_VideoController)
$FirmwareSecurity = Get-FirmwareSecurityInfo

$StorageControllers = @(
    Get-CimInstance Win32_PnPSignedDriver |
        Where-Object {
            $_.DeviceClass -match 'HDC|SCSIAdapter' -or
            $_.DeviceName -match 'AHCI|RAID|RST|VMD|NVMe|Storage Controller|SATA'
        } |
        Select-Object DeviceName, DeviceClass, Manufacturer, DriverProviderName, DriverVersion
)

# Memory installability / slot interpretation.
# MemoryDevices from SMBIOS is NOT treated blindly as a physical replaceable slot count.
$MemoryInstall = Get-MemoryInstallability -Computer $Computer -Product $Product -RAM $RAM -MemArray $MemArray
$ReportedMemorySlots = $MemoryInstall.SMBIOSMemoryDevices
$UsedMemorySlots = $MemoryInstall.DetectedModules

if ($MemoryInstall.PhysicalSlots -is [int]) {
    $PhysicalMemorySlots = [int]$MemoryInstall.PhysicalSlots
    $EmptyMemorySlots = [Math]::Max(0, $PhysicalMemorySlots - $UsedMemorySlots)
} else {
    $PhysicalMemorySlots = "-"
    $EmptyMemorySlots = "-"
}

$MemorySlotText = "増設可否: $($MemoryInstall.Installable) / 物理スロット: $PhysicalMemorySlots / 検出メモリ: $UsedMemorySlots"

# ============================================================
# Office / Microsoft 365 detection
# ============================================================
Show-Step "Officeを確認しています..."

$OfficeInfo = @()

$officeRegistryPaths = @(
    'HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun\Configuration'
)

foreach ($path in $officeRegistryPaths) {
    if (Test-Path $path) {
        try {
            $o = Get-ItemProperty $path
            if ($o.ProductReleaseIds) {
                $OfficeInfo += [PSCustomObject]@{
                    Type     = "ClickToRun"
                    Product  = $o.ProductReleaseIds
                    Version  = $o.VersionToReport
                    Platform = $o.Platform
                    Channel  = $o.CDNBaseUrl
                }
            }
        } catch {}
    }
}

$uninstallPaths = @(
    'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
)

foreach ($path in $uninstallPaths) {
    try {
        Get-ItemProperty $path |
            Where-Object {
                $_.DisplayName -match 'Microsoft (Office|365)' -and
                $_.DisplayName -notmatch 'Update|Language Pack|Proofing|OneDrive'
            } |
            ForEach-Object {
                $OfficeInfo += [PSCustomObject]@{
                    Type     = "InstalledProduct"
                    Product  = $_.DisplayName
                    Version  = $_.DisplayVersion
                    Platform = ""
                    Channel  = ""
                }
            }
    } catch {}
}

$OfficeInfo = @($OfficeInfo | Sort-Object Product, Version -Unique)

if ($OfficeInfo.Count -gt 0) {
    $OfficeDetectedText = ($OfficeInfo | ForEach-Object { $_.Product }) -join " / "
} else {
    $OfficeDetectedText = "未検出"
}

$AntivirusInfo = Get-AntivirusStatus
$AntivirusDetectedText = if ($AntivirusInfo.Count -gt 0) {
    ($AntivirusInfo | ForEach-Object { $_.Name }) -join ' / '
} else {
    '未検出'
}

$CpuPassMarkScore = Get-ApproxPassMarkScore -CpuName $CPU.Name
$CpuPassMarkText = if ($CpuPassMarkScore) { "$CpuPassMarkScore" } else { "未登録" }

Show-Step "Windows / Office ライセンス状態を確認しています..."

$WindowsLicenseInfo = @(Get-WindowsLicenseInfo)
$OfficeLicenseInfo = @(Get-OfficeLicenseInfo)
$WindowsFullProductKey = Get-FullWindowsProductKey
$WindowsFullProductKeyText = if ($WindowsFullProductKey) { $WindowsFullProductKey } else { "取得不可（デジタルライセンス等）" }
$OfficeFullProductKeyText = "認証キー走査省略（高速化）"

$WindowsLicenseText = if ($WindowsLicenseInfo.Count -gt 0) {
    ($WindowsLicenseInfo | ForEach-Object {
        "$($_.LicenseStatus) / $($_.ProductKeyChannel) / Key末尾:$($_.PartialProductKey)"
    }) -join " | "
} else {
    "取得不可 / 未検出"
}

$OfficeLicenseText = if ($OfficeLicenseInfo.Count -gt 0) {
    ($OfficeLicenseInfo | ForEach-Object {
        "$($_.LicenseStatus) / $($_.ProductKeyChannel) / Key末尾:$($_.PartialProductKey)"
    }) -join " | "
} elseif ($OfficeInfo.Count -gt 0) {
    "Officeは検出済み / ライセンス状態は取得不可"
} else {
    "Office未検出"
}

# ============================================================
# Main log
# ============================================================
"============================================================" | Out-File $MainLog -Encoding UTF8
" 修理案件 PC情報ログ v6.19" | Out-File $MainLog -Append -Encoding UTF8
"============================================================" | Out-File $MainLog -Append -Encoding UTF8
Add-Line "案件番号        : No.$CaseNo"
Add-Line "取得モード      : $ModeName"
Add-Line "取得日時        : $(Get-Date -Format 'yyyy/MM/dd HH:mm:ss')"
Add-Line "コンピューター  : $env:COMPUTERNAME"
Add-Line "ログオンユーザー: $env:USERNAME"
Add-Line "管理者権限      : $isAdmin"

Add-Section "本体情報" {
    [PSCustomObject]@{
        Manufacturer      = $Computer.Manufacturer
        Model             = $Computer.Model
        ProductName       = $Product.Name
        ProductVersion    = $Product.Version
        SerialNumber      = $BIOS.SerialNumber
        UUID              = $Product.UUID
        TotalMemoryGB     = [math]::Round($Computer.TotalPhysicalMemory / 1GB, 2)
    } | Format-List
}

Add-Section "CPU" {
    $obj = [PSCustomObject]@{
        Name                     = $CPU.Name
        Manufacturer             = $CPU.Manufacturer
        NumberOfCores            = $CPU.NumberOfCores
        NumberOfLogicalProcessors= $CPU.NumberOfLogicalProcessors
        MaxClockSpeed            = $CPU.MaxClockSpeed
        CurrentClockSpeed        = $CPU.CurrentClockSpeed
        ApproxPassMarkScore      = $CpuPassMarkText
    }
    $obj | Format-List
}

Add-Section "物理メモリ" {
    if ($RAM.Count -eq 0) {
        "メモリモジュール情報を取得できませんでした。"
    } else {
        $RAM | Select-Object BankLabel, DeviceLocator,
            @{N="CapacityGB";E={[math]::Round($_.Capacity / 1GB, 2)}},
            Speed, ConfiguredClockSpeed, Manufacturer, PartNumber, SerialNumber |
            Format-Table -AutoSize
    }
}

Add-Section "メモリスロット / 増設可否" {
    "増設可否             : $($MemoryInstall.Installable)"
    "判定理由             : $($MemoryInstall.Reason)"
    "判定信頼度           : $($MemoryInstall.Confidence)"
    "物理メモリスロット   : $PhysicalMemorySlots"
    "検出メモリモジュール : $UsedMemorySlots"
    "空きスロット         : $EmptyMemorySlots"
    "SMBIOS MemoryDevices : $ReportedMemorySlots"
    ""
    "※ SMBIOS MemoryDevices は物理SO-DIMMスロット数と一致しない機種があります。"
    "※ オンボードメモリ機では、MemoryDevicesが1以上でも増設不可の場合があります。"
}

Add-Section "ストレージ" {
    $physicalDisks = @(Get-PhysicalDisk)

    $rows = @()
    foreach ($d in $Disks) {
        $pd = $physicalDisks |
            Where-Object {
                ($_.SerialNumber -and $d.SerialNumber -and
                 $_.SerialNumber.Trim() -eq $d.SerialNumber.Trim()) -or
                ($_.FriendlyName -and $d.Model -and
                 $d.Model -like "*$($_.FriendlyName)*")
            } |
            Select-Object -First 1

        $connection = Get-StorageConnectionType -Disk $d -PhysicalDisk $pd -Controllers $StorageControllers
        $optane = Test-Optane -Disk $d -PhysicalDisk $pd -Controllers $StorageControllers

        $rows += [PSCustomObject]@{
            Model          = $d.Model
            SizeGB         = [math]::Round($d.Size / 1GB, 2)
            MediaType      = if ($pd) { $pd.MediaType } else { $d.MediaType }
            Connection     = $connection
            OptaneDetected = $optane
            SerialNumber   = $d.SerialNumber
            Firmware       = $d.FirmwareRevision
        }
    }

    $rows | Format-Table -AutoSize
    ""
    "検出ストレージコントローラー:"
    $StorageControllers | Select-Object DeviceName, Manufacturer,
        DriverProviderName, DriverVersion | Format-Table -AutoSize
}

Add-Section "ボリューム / ドライブ容量" {
    Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" |
        Sort-Object DeviceID |
        Select-Object @{N="Drive";E={$_.DeviceID}},
            @{N="VolumeLabel";E={$_.VolumeName}},
            FileSystem,
            @{N="TotalGB";E={[math]::Round($_.Size / 1GB, 2)}},
            @{N="FreeGB";E={[math]::Round($_.FreeSpace / 1GB, 2)}},
            @{N="UsedGB";E={[math]::Round(($_.Size - $_.FreeSpace) / 1GB, 2)}},
            @{N="FreePercent";E={ if ($_.Size) { [math]::Round(($_.FreeSpace / $_.Size) * 100, 1) } }} |
        Format-Table -AutoSize
}

Add-Section "Windows" {
    [PSCustomObject]@{
        Caption        = $OS.Caption
        Version        = $OS.Version
        BuildNumber    = $OS.BuildNumber
        Architecture   = $OS.OSArchitecture
        InstallDate    = $OS.InstallDate
        LastBootUpTime = $OS.LastBootUpTime
    } | Format-List
}

Add-Section "Microsoft Office / Microsoft 365" {
    if ($OfficeInfo.Count -gt 0) {
        $OfficeInfo | Select-Object Type, Product, Version, Platform, Channel |
            Format-Table -AutoSize
    } else {
        "Office / Microsoft 365 は検出されませんでした。"
    }
}


Add-Section "ウイルス対策ソフト" {
    if ($AntivirusInfo.Count -gt 0) {
        $AntivirusInfo | Format-Table -AutoSize
    } else {
        "ウイルス対策ソフトは検出されませんでした。"
    }
}


Add-Section "Windows ライセンス" {
    "完全プロダクトキー : $WindowsFullProductKeyText"
    ""
    if ($WindowsLicenseInfo.Count -gt 0) {
        $WindowsLicenseInfo |
            Select-Object Name, Description, LicenseStatus, ProductKeyChannel,
                PartialProductKey, GraceMinutes |
            Format-Table -Wrap -AutoSize
    } else {
        "Windowsライセンス情報を取得できませんでした。"
    }
}

Add-Section "Office ライセンス" {
    "完全プロダクトキー : $OfficeFullProductKeyText"
    ""
    if ($OfficeLicenseInfo.Count -gt 0) {
        $OfficeLicenseInfo |
            Select-Object Name, Description, LicenseStatus, ProductKeyChannel,
                PartialProductKey |
            Format-Table -Wrap -AutoSize
    } elseif ($OfficeInfo.Count -gt 0) {
        "Office製品は検出しましたが、ライセンス状態は取得できませんでした。"
    } else {
        "Office / Microsoft 365 は未検出です。"
    }
}



Add-Section "イベントビューア 危険信号サマリー" {
    $signals = @(Get-EventDangerSignals -Days 30 -MaxEvents 1000)
    [PSCustomObject]@{
        CriticalCount = @($signals | Where-Object { $_.Severity -eq "重大" }).Count
        WarningCount  = @($signals | Where-Object { $_.Severity -eq "警告" }).Count
        CriticalProcessDied = @($signals | Where-Object { $_.Category -eq "CRITICAL_PROCESS_DIED" }).Count
        KernelPower41 = @($signals | Where-Object { $_.Category -eq "Kernel-Power" }).Count
        WHEA          = @($signals | Where-Object { $_.Category -match "WHEA" }).Count
        Storage       = @($signals | Where-Object { $_.Category -eq "ストレージ / ファイルシステム" }).Count
    } | Format-List
}

Add-Section "Firmware / Secure Boot / TPM" {
    $FirmwareSecurity | Format-List
}

Add-Section "BIOS" {
    $BIOS | Select-Object Manufacturer, SMBIOSBIOSVersion,
        Version, SerialNumber, ReleaseDate | Format-List
}

Add-Section "マザーボード" {
    Get-CimInstance Win32_BaseBoard |
        Select-Object Manufacturer, Product, Version, SerialNumber |
        Format-List
}

Add-Section "GPU / ドライバ" {
    $GPU | Select-Object @{N="GPU";E={$_.Name}},
        @{N="DriverVersion";E={$_.DriverVersion}},
        @{N="DriverDate";E={$_.DriverDate}},
        @{N="Resolution";E={"$($_.CurrentHorizontalResolution)x$($_.CurrentVerticalResolution)"}},
        @{N="RefreshRate";E={$_.CurrentRefreshRate}},
        @{N="VideoMode";E={$_.VideoModeDescription}} |
        Format-Table -AutoSize
}

Add-Section "PnPデバイス異常" {
    $bad = Get-CimInstance Win32_PnPEntity |
        Where-Object { $_.ConfigManagerErrorCode -ne 0 }

    if ($bad) {
        $bad | Select-Object Name, Status, ConfigManagerErrorCode, PNPDeviceID |
            Format-Table -AutoSize
    } else {
        "異常コード付きPnPデバイスは検出されませんでした。"
    }
}

# ============================================================
# Battery
# ============================================================
Show-Step "バッテリー情報を取得しています..."

$BatteryManufacturerText = "-"
$BatteryModelText = "-"
$BatteryDesignCapacityText = "-"
$BatteryFullChargeCapacityText = "-"
$BatteryCurrentCapacityText = "-"
$BatteryHealthText = "-"
$BatteryLifePercentText = "-"

Add-Section "バッテリー仕様 / 状態" {
    $battery = Get-CimInstance Win32_Battery
    $static  = Get-CimInstance -Namespace root\wmi -ClassName BatteryStaticData
    $full    = Get-CimInstance -Namespace root\wmi -ClassName BatteryFullChargedCapacity
    $status  = Get-CimInstance -Namespace root\wmi -ClassName BatteryStatus

    if (-not $battery -and -not $static -and -not $full) {
        "バッテリー情報なし。"
        return
    }

    if ($battery) {
        $battery | Select-Object Name, DeviceID, Status, BatteryStatus,
            EstimatedChargeRemaining, EstimatedRunTime, DesignVoltage |
            Format-List
    }

    if ($static) {
        $static | Select-Object ManufacturerName, DeviceName,
            SerialNumber, ManufactureDate, DesignedCapacity |
            Format-List
    }

    if ($full) {
        $full | Select-Object FullChargedCapacity |
            Format-List
    }

    if ($status) {
        $status | Select-Object PowerOnline, Charging, Discharging,
            Critical, RemainingCapacity, Voltage, ChargeRate, DischargeRate |
            Format-List

        $status1 = @($status) | Select-Object -First 1
        if ($status1.RemainingCapacity) {
            $script:BatteryCurrentCapacityText = "$($status1.RemainingCapacity) mWh"
        }
    }

    $s1 = @($static) | Select-Object -First 1
    $f1 = @($full) | Select-Object -First 1

    if ($s1) {
        if ($s1.ManufacturerName) {
            $script:BatteryManufacturerText = $s1.ManufacturerName
        }
        if ($s1.DeviceName) {
            $script:BatteryModelText = $s1.DeviceName
        }
        if ($s1.DesignedCapacity) {
            $script:BatteryDesignCapacityText = "$($s1.DesignedCapacity) mWh"
        }
    }

    if ($script:BatteryModelText -eq "-" -and $battery) {
        $b1 = @($battery) | Select-Object -First 1
        if ($b1.Name) {
            $script:BatteryModelText = $b1.Name
        } elseif ($b1.DeviceID) {
            $script:BatteryModelText = $b1.DeviceID
        }
    }

    if ($f1 -and $f1.FullChargedCapacity) {
        $script:BatteryFullChargeCapacityText = "$($f1.FullChargedCapacity) mWh"
    }

    if ($s1 -and $f1 -and $s1.DesignedCapacity -gt 0 -and $f1.FullChargedCapacity -gt 0) {
        $health = [math]::Round(($f1.FullChargedCapacity / $s1.DesignedCapacity) * 100, 1)
        $wear = [math]::Round(100 - $health, 1)
        $script:BatteryHealthText = "$health %（劣化 $wear %）"
        $script:BatteryLifePercentText = "$($f1.FullChargedCapacity) / $($s1.DesignedCapacity) mWh = $health %"

        [PSCustomObject]@{
            DesignedCapacitymWh   = $s1.DesignedCapacity
            FullChargeCapacitymWh = $f1.FullChargedCapacity
            HealthPercent         = $health
            WearPercent           = $wear
        } | Format-List

        "バッテリー寿命目安 : $health %"
        "劣化率             : $wear %"
    }
}

try {
    powercfg.exe /batteryreport /output "$BatteryLog" | Out-Null
    if (-not (Test-Path $BatteryLog)) {
        Remove-Item $BatteryLog -Force -ErrorAction SilentlyContinue
    }
} catch {}

# ============================================================
# SMART / reliability
# ============================================================
Show-Step "SMART / ストレージ信頼性情報を取得しています..."

$SmartRows = @()
$SmartFallback = @()

"============================================================" | Out-File $SmartLog -Encoding UTF8
" SMART / Storage Reliability Report" | Out-File $SmartLog -Append -Encoding UTF8
"============================================================" | Out-File $SmartLog -Append -Encoding UTF8
"案件番号: No.$CaseNo" | Out-File $SmartLog -Append -Encoding UTF8
"取得日時: $(Get-Date -Format 'yyyy/MM/dd HH:mm:ss')" | Out-File $SmartLog -Append -Encoding UTF8
"" | Out-File $SmartLog -Append -Encoding UTF8

try {
    $physicalDisks = @(Get-PhysicalDisk)

    foreach ($pd in $physicalDisks) {
        $rc = $null
        try {
            $rc = Get-StorageReliabilityCounter -PhysicalDisk $pd
        } catch {}

        $matchedDisk = $Disks |
            Where-Object {
                ($_.SerialNumber -and $pd.SerialNumber -and
                 $_.SerialNumber.Trim() -eq $pd.SerialNumber.Trim()) -or
                ($_.Model -and $pd.FriendlyName -and
                 $_.Model -like "*$($pd.FriendlyName)*")
            } |
            Select-Object -First 1

        $connection = Get-StorageConnectionType -Disk $matchedDisk -PhysicalDisk $pd -Controllers $StorageControllers
        $optane = Test-Optane -Disk $matchedDisk -PhysicalDisk $pd -Controllers $StorageControllers

        $SmartRows += [PSCustomObject]@{
            FriendlyName      = $pd.FriendlyName
            SerialNumber      = $pd.SerialNumber
            MediaType         = $pd.MediaType
            ConnectionType    = $connection
            OptaneDetected    = $optane
            SizeGB            = [math]::Round($pd.Size / 1GB, 2)
            HealthStatus      = $pd.HealthStatus
            OperationalStatus = ($pd.OperationalStatus -join ", ")
            TemperatureC      = if ($rc) { $rc.Temperature } else { $null }
            WearPercent       = if ($rc) { $rc.Wear } else { $null }
            PowerOnHours      = if ($rc) { $rc.PowerOnHours } else { $null }
            ReadErrorsTotal   = if ($rc) { $rc.ReadErrorsTotal } else { $null }
            WriteErrorsTotal  = if ($rc) { $rc.WriteErrorsTotal } else { $null }
        }
    }
} catch {}

if ($SmartRows.Count -gt 0) {
    $SmartRows | Format-List | Out-String -Width 300 |
        Out-File $SmartLog -Append -Encoding UTF8
}

try {
    $predict = @(Get-CimInstance -Namespace root\wmi -ClassName MSStorageDriver_FailurePredictStatus)
    foreach ($p in $predict) {
        $SmartFallback += [PSCustomObject]@{
            InstanceName   = $p.InstanceName
            PredictFailure = $p.PredictFailure
            Reason         = $p.Reason
        }
    }
} catch {}

if ($SmartFallback.Count -gt 0) {
    "" | Out-File $SmartLog -Append -Encoding UTF8
    "---- Failure Predict ----" | Out-File $SmartLog -Append -Encoding UTF8
    $SmartFallback | Format-List | Out-String -Width 300 |
        Out-File $SmartLog -Append -Encoding UTF8
}

if ($SmartRows.Count -eq 0 -and $SmartFallback.Count -eq 0) {
    "SMART情報を取得できませんでした。" |
        Out-File $SmartLog -Append -Encoding UTF8
}


$AtaSmartAttributes = @(Get-AtaSmartAttributes)

if ($AtaSmartAttributes.Count -gt 0) {
    "" | Out-File $SmartLog -Append -Encoding UTF8
    "============================================================" | Out-File $SmartLog -Append -Encoding UTF8
    " ATA SMART Attributes 詳細" | Out-File $SmartLog -Append -Encoding UTF8
    "============================================================" | Out-File $SmartLog -Append -Encoding UTF8

    $AtaSmartAttributes |
        Sort-Object InstanceName, ID |
        Format-Table InstanceName, ID, Name, Current, Worst, Threshold, RawValue, Flags -AutoSize |
        Out-String -Width 500 |
        Out-File $SmartLog -Append -Encoding UTF8
}

# ============================================================
# Detailed mode
# ============================================================
if ($Mode -eq "2") {
    Show-Step "詳細モード: ドライバ情報を取得しています..."

    Add-Section "主要ドライバー" {
        Get-CimInstance Win32_PnPSignedDriver |
            Where-Object {
                $_.DeviceName -and
                $_.DeviceClass -match 'DISPLAY|NET|MEDIA|HDC|SCSIAdapter|System|Bluetooth'
            } |
            Select-Object DeviceClass, DeviceName, Manufacturer,
                DriverProviderName, DriverVersion, DriverDate, InfName |
            Sort-Object DeviceClass, DeviceName |
            Format-Table -AutoSize
    }

    Add-Section "Windows Update / HotFix（直近30件）" {
        Get-HotFix |
            Sort-Object InstalledOn -Descending |
            Select-Object -First 30 HotFixID, Description, InstalledBy, InstalledOn |
            Format-Table -AutoSize
    }

    Add-Section "最近のシステムエラー（直近3日 / 最大30件）" {
        $start = (Get-Date).AddDays(-3)
        Get-WinEvent -FilterHashtable @{
            LogName   = 'System'
            Level     = 1,2
            StartTime = $start
        } -MaxEvents 30 |
            Select-Object TimeCreated, Id, ProviderName, LevelDisplayName,
                @{N="Message";E={($_.Message -replace "`r|`n",' ')}} |
            Format-Table -Wrap
    }

    try {
        Start-Process -FilePath "msinfo32.exe" `
            -ArgumentList "/report `"$MsInfoLog`" /categories +systemsummary+componentsproblemdevices+resourcesconflicts" `
            -Wait -WindowStyle Hidden
    } catch {}

    try {
        Start-Process -FilePath "dxdiag.exe" `
            -ArgumentList "/dontskip /t `"$DxDiagLog`"" `
            -Wait -WindowStyle Hidden
    } catch {}
}

# ============================================================
# Image 1
# ============================================================
Show-Step "主要スペック画像を生成しています..."

$ramText = "$([math]::Round($Computer.TotalPhysicalMemory / 1GB, 1)) GB / $UsedMemorySlots 枚"

$physicalDisksForImage = @(Get-PhysicalDisk)
$diskLines = @()

foreach ($d in $Disks) {
    $pd = $physicalDisksForImage |
        Where-Object {
            ($_.SerialNumber -and $d.SerialNumber -and
             $_.SerialNumber.Trim() -eq $d.SerialNumber.Trim()) -or
            ($_.FriendlyName -and $d.Model -and
             $d.Model -like "*$($_.FriendlyName)*")
        } |
        Select-Object -First 1

    $connection = Get-StorageConnectionType -Disk $d -PhysicalDisk $pd -Controllers $StorageControllers
    $optane = Test-Optane -Disk $d -PhysicalDisk $pd -Controllers $StorageControllers
    $optaneText = if ($optane) { " / Optane検出" } else { "" }

    $diskLines += "$($d.Model) / $([math]::Round($d.Size / 1GB, 0)) GB / $connection$optaneText"
}

$ManufacturerName = [string]$Computer.Manufacturer
$SerialNumberText = [string]$BIOS.SerialNumber
$VendorExtraLines = @()

if ($ManufacturerName -match '(?i)Dell') {
    $dellServiceTag = $SerialNumberText
    $dellExpressCode = Convert-DellServiceTagToExpressCode -ServiceTag $dellServiceTag

    $VendorExtraLines += "Service Tag: $dellServiceTag"
    $VendorExtraLines += "Express Service Code: $dellExpressCode"
}
elseif ($ManufacturerName -match '(?i)HP|Hewlett-Packard') {
    $hpProductNumber = "-"

    try {
        $biosReg = Get-ItemProperty "HKLM:\HARDWARE\DESCRIPTION\System\BIOS" -ErrorAction SilentlyContinue
        if ($biosReg.SystemSKU) {
            $hpProductNumber = [string]$biosReg.SystemSKU
        }
    } catch {}

    if ($hpProductNumber -eq "-" -and $Product.Version) {
        $hpProductNumber = [string]$Product.Version
    }

    $VendorExtraLines += "Product Number / System SKU: $hpProductNumber"
}

$spec1Lines = @(
    "## 本体",
    "メーカー: $($Computer.Manufacturer)",
    "モデル名: $($Computer.Model)",
    "S/N: $($BIOS.SerialNumber)"
)

foreach ($line in $VendorExtraLines) {
    $spec1Lines += $line
}

$spec1Lines += @(
    "",
    "## CPU",
    "CPU: $($CPU.Name)",
    "PassMark目安: $CpuPassMarkText",
    "コア / スレッド: $($CPU.NumberOfCores) / $($CPU.NumberOfLogicalProcessors)",
    "",
    "## メモリ",
    "総容量: $ramText",
    "搭載枚数: $UsedMemorySlots",
    "増設可否: $($MemoryInstall.Installable)",
    "物理メモリスロット: $PhysicalMemorySlots",
    "空きスロット: $EmptyMemorySlots",
    "判定: $($MemoryInstall.Reason)",
    "注意: 増設可能表示でも交換可能とは限りません。",
    "注意: メーカー公式情報・保守資料・欧米レビュアー等の分解情報を要確認。",
    "",
    "## ストレージ"
)

foreach ($line in $diskLines) {
    $spec1Lines += "・$line"
}

$spec1Lines += @(
    "",
    "## ボリューム"
)

$vols = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | Sort-Object DeviceID
foreach ($v in $vols) {
    $spec1Lines += "$($v.DeviceID) / $($v.VolumeName) / $([math]::Round($v.Size / 1GB, 0)) GB"
}

$spec1Lines += @(
    "",
    "## GPU"
)

foreach ($v in $GPU) {
    if ($v.Name) {
        $spec1Lines += "GPU: $($v.Name)"
        $spec1Lines += "Driver: $($v.DriverVersion)"
    }
}

$spec1Lines += @(
    "",
    "## バッテリー",
    "型番: $BatteryModelText",
    "設計容量: $BatteryDesignCapacityText",
    "満充電容量: $BatteryFullChargeCapacityText",
    "現在容量: $BatteryCurrentCapacityText",
    "寿命: $BatteryHealthText",
    "寿命計算: $BatteryLifePercentText",
    "劣化率: $BatteryWearText",
    "状態: $BatteryStatusText",
    "サイクル回数: $BatteryCycleCountText",
    "",
    "## OS / セキュリティ / Office",
    "OS: $($OS.Caption)  Build $($OS.BuildNumber)",
    "ウイルス対策: $AntivirusDetectedText",
    "Office: $OfficeDetectedText",
    "Office認証: 詳細走査省略（高速モード）"
)

$img1ok = New-InfoPng `
    -Path $SpecImage1 `
    -Title "主要スペック 1" `
    -SubTitle "No.$CaseNo / $($Computer.Manufacturer) $($Computer.Model)" `
    -Lines $spec1Lines `
    -CaptureTime $CaptureTimestamp


# ============================================================
# Image 2
# ============================================================
$spec2Lines = @(
    "## SSD / HDD / NVMe - SMART / 信頼性情報"
)

if ($SmartRows.Count -gt 0) {
    $i = 1

    foreach ($s in $SmartRows) {
        $spec2Lines += "Disk ${i}: $($s.FriendlyName)"
        $spec2Lines += "  容量: $(Format-Value $s.SizeGB ' GB') / 種別: $(Format-Value $s.MediaType)"
        $spec2Lines += "  接続方式: $(Format-Value $s.ConnectionType) / Optane: $($s.OptaneDetected)"
        $spec2Lines += "  Health: $(Format-Value $s.HealthStatus) / Operational: $(Format-Value $s.OperationalStatus)"
        $spec2Lines += "  温度: $(Format-Value $s.TemperatureC ' ℃') / Wear: $(Format-Value $s.WearPercent ' %')"
        $spec2Lines += "  使用時間: $(Format-Value $s.PowerOnHours ' h')"
        $spec2Lines += "  Read Error: $(Format-Value $s.ReadErrorsTotal) / Write Error: $(Format-Value $s.WriteErrorsTotal)"
        $spec2Lines += "  S/N: $($s.SerialNumber)"
        $spec2Lines += ""
        $i++
    }
} elseif ($SmartFallback.Count -gt 0) {
    foreach ($s in $SmartFallback) {
        $spec2Lines += "PredictFailure: $($s.PredictFailure)"
        $spec2Lines += "Reason: $($s.Reason)"
        $spec2Lines += "Device: $($s.InstanceName)"
        $spec2Lines += ""
    }
} else {
    $spec2Lines += "SMART情報を取得できませんでした。"
}


if ($AtaSmartAttributes.Count -gt 0) {
    $importantIds = @(5, 9, 12, 187, 194, 197, 198, 199, 202, 231, 233, 241, 242)
    $importantSmart = @($AtaSmartAttributes | Where-Object { $importantIds -contains $_.ID })

    if ($importantSmart.Count -gt 0) {
        $spec2Lines += ""
        $spec2Lines += "## 主要SMART属性"
        foreach ($a in $importantSmart) {
            $spec2Lines += "ID $($a.ID) $($a.Name): Current=$($a.Current) / Raw=$($a.RawValue)"
        }
    }
}

$img2ok = New-InfoPng `
    -Path $SpecImage2 `
    -Title "主要スペック 2 - SMART" `
    -SubTitle "No.$CaseNo / Storage Health" `
    -Lines $spec2Lines


# ============================================================
# Event Viewer danger signal report
# ============================================================
Show-Step "イベントビューアの危険信号を確認しています..."

$DangerSignals = @(Get-EventDangerSignals -Days 30 -MaxEvents 1000)

"============================================================" | Out-File $DangerEventLog -Encoding UTF8
" Event Viewer 危険信号レポート" | Out-File $DangerEventLog -Append -Encoding UTF8
"============================================================" | Out-File $DangerEventLog -Append -Encoding UTF8
"案件番号: No.$CaseNo" | Out-File $DangerEventLog -Append -Encoding UTF8
"取得日時: $(Get-Date -Format 'yyyy/MM/dd HH:mm:ss')" | Out-File $DangerEventLog -Append -Encoding UTF8
"対象期間: 過去30日" | Out-File $DangerEventLog -Append -Encoding UTF8
"" | Out-File $DangerEventLog -Append -Encoding UTF8

$criticalCount = @($DangerSignals | Where-Object { $_.Severity -eq "重大" }).Count
$warningCount = @($DangerSignals | Where-Object { $_.Severity -eq "警告" }).Count

"重大: $criticalCount 件" | Out-File $DangerEventLog -Append -Encoding UTF8
"警告: $warningCount 件" | Out-File $DangerEventLog -Append -Encoding UTF8
"" | Out-File $DangerEventLog -Append -Encoding UTF8

if ($DangerSignals.Count -eq 0) {
    "危険信号として定義したイベントは検出されませんでした。" |
        Out-File $DangerEventLog -Append -Encoding UTF8
} else {
    foreach ($sig in $DangerSignals) {
        "------------------------------------------------------------" | Out-File $DangerEventLog -Append -Encoding UTF8
        "日時      : $($sig.TimeCreated)" | Out-File $DangerEventLog -Append -Encoding UTF8
        "重要度    : $($sig.Severity)" | Out-File $DangerEventLog -Append -Encoding UTF8
        "カテゴリ  : $($sig.Category)" | Out-File $DangerEventLog -Append -Encoding UTF8
        "Provider  : $($sig.Provider)" | Out-File $DangerEventLog -Append -Encoding UTF8
        "Event ID  : $($sig.EventID)" | Out-File $DangerEventLog -Append -Encoding UTF8
        "判定理由  : $($sig.Reason)" | Out-File $DangerEventLog -Append -Encoding UTF8
        "Message   : $($sig.Message)" | Out-File $DangerEventLog -Append -Encoding UTF8
        "" | Out-File $DangerEventLog -Append -Encoding UTF8
    }
}

"" | Out-File $DangerEventLog -Append -Encoding UTF8
"[主な監視対象]" | Out-File $DangerEventLog -Append -Encoding UTF8
"・CRITICAL_PROCESS_DIED / BugCheck 0xEF" | Out-File $DangerEventLog -Append -Encoding UTF8
"・Kernel-Power Event ID 41" | Out-File $DangerEventLog -Append -Encoding UTF8
"・WHEA-Logger ハードウェアエラー" | Out-File $DangerEventLog -Append -Encoding UTF8
"・Disk / StorAHCI / StorNVMe / iaStor / NTFS / volmgr 異常" | Out-File $DangerEventLog -Append -Encoding UTF8
"・EventLog 6008 予期しないシャットダウン" | Out-File $DangerEventLog -Append -Encoding UTF8
"・GPU / ディスプレイドライバ停止・回復" | Out-File $DangerEventLog -Append -Encoding UTF8
"・重要Windowsシステムプロセスのクラッシュ" | Out-File $DangerEventLog -Append -Encoding UTF8
"" | Out-File $DangerEventLog -Append -Encoding UTF8
"※ 本レポートは故障確定ではなく、修理時に優先確認すべきイベントを抽出するものです。" |
    Out-File $DangerEventLog -Append -Encoding UTF8

# ============================================================
# Firmware / Secure Boot / TPM report
# ============================================================
"============================================================" | Out-File $FirmwareLog -Encoding UTF8
" Firmware / Secure Boot / TPM / Windows 11 要件" | Out-File $FirmwareLog -Append -Encoding UTF8
"============================================================" | Out-File $FirmwareLog -Append -Encoding UTF8
"案件番号: No.$CaseNo" | Out-File $FirmwareLog -Append -Encoding UTF8
"取得日時: $(Get-Date -Format 'yyyy/MM/dd HH:mm:ss')" | Out-File $FirmwareLog -Append -Encoding UTF8
"" | Out-File $FirmwareLog -Append -Encoding UTF8

"Firmware方式        : $($FirmwareSecurity.FirmwareType)" | Out-File $FirmwareLog -Append -Encoding UTF8
"Secure Boot         : $($FirmwareSecurity.SecureBoot)" | Out-File $FirmwareLog -Append -Encoding UTF8
"TPM搭載             : $($FirmwareSecurity.TpmPresent)" | Out-File $FirmwareLog -Append -Encoding UTF8
"TPM Ready           : $($FirmwareSecurity.TpmReady)" | Out-File $FirmwareLog -Append -Encoding UTF8
"TPM Enabled         : $($FirmwareSecurity.TpmEnabled)" | Out-File $FirmwareLog -Append -Encoding UTF8
"TPM Activated       : $($FirmwareSecurity.TpmActivated)" | Out-File $FirmwareLog -Append -Encoding UTF8
"TPM仕様             : $($FirmwareSecurity.TpmSpecVersion)" | Out-File $FirmwareLog -Append -Encoding UTF8
"TPMメーカー         : $($FirmwareSecurity.TpmManufacturer)" | Out-File $FirmwareLog -Append -Encoding UTF8
"" | Out-File $FirmwareLog -Append -Encoding UTF8

"[Windows 11 主要要件チェック]" | Out-File $FirmwareLog -Append -Encoding UTF8
"UEFI要件            : $($FirmwareSecurity.Windows11_UEFI_Req)" | Out-File $FirmwareLog -Append -Encoding UTF8
"Secure Boot要件     : $($FirmwareSecurity.Windows11_SecureBootReq)" | Out-File $FirmwareLog -Append -Encoding UTF8
"TPM 2.0要件         : $($FirmwareSecurity.Windows11_TPM_Req)" | Out-File $FirmwareLog -Append -Encoding UTF8
"" | Out-File $FirmwareLog -Append -Encoding UTF8

"[参考]" | Out-File $FirmwareLog -Append -Encoding UTF8
"Windows 11の主要ファームウェア要件: UEFI、Secure Boot対応、TPM 2.0。" | Out-File $FirmwareLog -Append -Encoding UTF8
"CPU世代、RAM、ストレージ容量等のその他要件は別途主要スペック情報を参照。" | Out-File $FirmwareLog -Append -Encoding UTF8

# ============================================================
# Separate license report / image
# ============================================================
"============================================================" | Out-File $LicenseLog -Encoding UTF8
" Windows / Office ライセンス情報" | Out-File $LicenseLog -Append -Encoding UTF8
"============================================================" | Out-File $LicenseLog -Append -Encoding UTF8
"案件番号: No.$CaseNo" | Out-File $LicenseLog -Append -Encoding UTF8
"取得日時: $(Get-Date -Format 'yyyy/MM/dd HH:mm:ss')" | Out-File $LicenseLog -Append -Encoding UTF8
"" | Out-File $LicenseLog -Append -Encoding UTF8

"[Windows]" | Out-File $LicenseLog -Append -Encoding UTF8
"完全プロダクトキー: $WindowsFullProductKeyText" | Out-File $LicenseLog -Append -Encoding UTF8
"" | Out-File $LicenseLog -Append -Encoding UTF8
if ($WindowsLicenseInfo.Count -gt 0) {
    $WindowsLicenseInfo |
        Format-List Name, Description, LicenseStatus, ProductKeyChannel,
            PartialProductKey, GraceMinutes |
        Out-String -Width 300 |
        Out-File $LicenseLog -Append -Encoding UTF8
} else {
    "取得不可 / 未検出" | Out-File $LicenseLog -Append -Encoding UTF8
}

"" | Out-File $LicenseLog -Append -Encoding UTF8
"[Office / Microsoft 365]" | Out-File $LicenseLog -Append -Encoding UTF8
"認証キー: $OfficeFullProductKeyText" | Out-File $LicenseLog -Append -Encoding UTF8
"" | Out-File $LicenseLog -Append -Encoding UTF8
if ($OfficeLicenseInfo.Count -gt 0) {
    $OfficeLicenseInfo |
        Format-List Name, Description, LicenseStatus, ProductKeyChannel,
            PartialProductKey |
        Out-String -Width 300 |
        Out-File $LicenseLog -Append -Encoding UTF8
} elseif ($OfficeInfo.Count -gt 0) {
    "Office製品はインストール済みですが、ライセンス状態は取得不可。" |
        Out-File $LicenseLog -Append -Encoding UTF8
    $OfficeInfo |
        Format-List |
        Out-String -Width 300 |
        Out-File $LicenseLog -Append -Encoding UTF8
} else {
    "Office / Microsoft 365 は未検出。" |
        Out-File $LicenseLog -Append -Encoding UTF8
}

$licenseLines = @(
    "## Windows",
    "状態: $WindowsLicenseText",
    "完全プロダクトキー: $WindowsFullProductKeyText",
    "",
    "## Office / Microsoft 365",
    "インストール: $OfficeDetectedText",
    "ライセンス: $OfficeLicenseText",
    "認証キー: $OfficeFullProductKeyText",
    "",
    "## 補足",
    "Windowsの完全キーはOEM/UEFI等から取得できた場合のみ表示します。",
    "Microsoft 365 / Click-to-Runでは完全なOfficeキーを取得できない場合があります。"
)

$licenseImgOk = New-InfoPng `
    -Path $LicenseImage `
    -Title "ライセンス情報" `
    -SubTitle "No.$CaseNo / Windows & Office" `
    -Lines $licenseLines


# ============================================================
# Tool change log
# ============================================================
try {
    $packagedChangeLog = Join-Path $PSScriptRoot "CHANGELOG.txt"
    if (Test-Path $packagedChangeLog) {
        Copy-Item -LiteralPath $packagedChangeLog -Destination $ChangeLogOut -Force
    }
} catch {}

# ============================================================
# End
# ============================================================
Write-Host ""
Write-Host "============================================================"
Write-Host " No.$CaseNo PC情報ログ取得完了"
Write-Host "============================================================"
Write-Host "取得モード : $ModeName"
Write-Host "出力先     : $OutDir"
Write-Host ""
Write-Host "生成物:"
Write-Host "  No.$SafeCaseNo-PCInfo.txt"
Write-Host "  No.$SafeCaseNo-SMART.txt"
if ($img1ok) { Write-Host "  主要スペック1.png" }
if ($img2ok) { Write-Host "  主要スペック2_SMART.png" }
Write-Host "  No.$SafeCaseNo-EventDangerSignals.txt"
Write-Host "  Tool_CHANGELOG.txt"
Write-Host "  No.$SafeCaseNo-FirmwareSecurity.txt"
Write-Host "  No.$SafeCaseNo-License.txt"
if ($licenseImgOk) { Write-Host "  ライセンス情報.png" }

if (-not $img1ok -or -not $img2ok -or -not $licenseImgOk) {
    Write-Host ""
    Write-Host "※ 一部の画像生成に失敗しました。"
    Write-Host "  ImageGeneration_Error.txt を確認してください。"
}
if (Test-Path $BatteryLog) { Write-Host "  battery-report.html" }
if (Test-Path $MsInfoLog) { Write-Host "  msinfo32.txt" }
if (Test-Path $DxDiagLog) { Write-Host "  dxdiag.txt" }
Write-Host ""
Read-Host "Enterキーで終了"
