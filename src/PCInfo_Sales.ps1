param(
    [string]$Directory,
    $Computer,
    [object[]]$Processors,
    [object[]]$Disks,
    [object[]]$Graphics,
    $OperatingSystem
)

# Only explicitly selected specifications go into customer-facing drafts.
$rows = New-Object 'System.Collections.Generic.List[object]'
function Add-SpecRow {
    param([string]$Label, [string]$Value)
    if ([string]::IsNullOrEmpty($Value) -or [string]::IsNullOrEmpty($Value.Trim())) { $Value = "取得不可" }
    $rows.Add(@($Label, ($Value -replace '[\r\n\t]+', ' ')))
}
function Format-SpecCapacity {
    param($Bytes, [double]$Unit, [string]$Suffix)
    if ($Bytes -gt 0) { return ("{0:0.##} {1}" -f ($Bytes / $Unit), $Suffix) }
    return "取得不可"
}

Add-SpecRow "メーカー" $Computer.Manufacturer
Add-SpecRow "モデル" $Computer.Model
if ($Processors.Count -eq 0) { Add-SpecRow "CPU" "" }
foreach ($processor in $Processors) { Add-SpecRow "CPU" $processor.Name }
Add-SpecRow "メモリ総容量" (Format-SpecCapacity $Computer.TotalPhysicalMemory 1GB "GiB")
if ($Disks.Count -eq 0) { Add-SpecRow "ストレージ" "" }
foreach ($disk in $Disks) {
    Add-SpecRow "ストレージのモデル" $disk.Model
    Add-SpecRow "ストレージ容量" (Format-SpecCapacity $disk.Size 1000000000 "GB")
}
if ($Graphics.Count -eq 0) { Add-SpecRow "GPU" "" }
foreach ($adapter in $Graphics) { Add-SpecRow "GPU" $adapter.Name }
Add-SpecRow "OS" $OperatingSystem.Caption
Add-SpecRow "OSバージョン" $OperatingSystem.Version

$listing = @("出品用情報（現物と照合してから転記）")
$html = @(
    '<!DOCTYPE html>',
    '<html lang="ja"><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8">',
    '<title>主要スペック</title><style type="text/css">@page{size:A4 portrait;margin:12mm}body{font:11pt sans-serif}table{border-collapse:collapse;width:100%}th,td{border:1px solid #888;padding:5px;text-align:left}</style></head>',
    '<body><h1>主要スペック</h1><table>'
)
foreach ($row in $rows) {
    $listing += "{0}: {1}" -f $row[0], $row[1]
    $label = [System.Security.SecurityElement]::Escape($row[0])
    $value = [System.Security.SecurityElement]::Escape($row[1])
    $html += '<tr><th scope="row">{0}</th><td>{1}</td></tr>' -f $label, $value
}
$html += '</table></body></html>'
$html | Out-File -LiteralPath (Join-Path $Directory "主要スペック.html") -Encoding UTF8 -ErrorAction Stop
$listing | Out-File -LiteralPath (Join-Path $Directory "出品用情報.txt") -Encoding UTF8 -ErrorAction Stop
@(
    "販売前チェック（担当者が確認）",
    "[ ] 現物と主要スペックを照合",
    "[ ] ストレージ診断・エラー診断を確認",
    "[ ] データ消去とライセンス条件を確認",
    "[ ] 出品用ファイルに社内情報が含まれないことを確認"
) | Out-File -LiteralPath (Join-Path $Directory "販売前チェック.txt") -Encoding UTF8 -ErrorAction Stop
