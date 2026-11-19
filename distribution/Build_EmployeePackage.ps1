param([string]$OutputDirectory = (Get-Location).Path)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$name = '社内PC診断ツール_v6.20_Preview'
$destination = (New-Item -ItemType Directory -Path $OutputDirectory -Force).FullName
$folder = Join-Path $destination $name
$archive = Join-Path $destination "$name.zip"
if ((Test-Path -LiteralPath $folder) -or (Test-Path -LiteralPath $archive)) {
    throw 'The output folder or archive already exists. Choose a new output directory.'
}

$system = New-Item -ItemType Directory -Path $folder | ForEach-Object {
    New-Item -ItemType Directory -Path (Join-Path $_.FullName 'system')
}
Copy-Item -LiteralPath (Join-Path $root 'launcher\PC診断ツールを起動.cmd'),
    (Join-Path $root 'distribution\はじめにお読みください.txt'),
    (Join-Path $root 'distribution\バージョン情報.txt') -Destination $folder

$runtime = @(
    'PCInfo_Launch.cmd', 'PCInfo_Modern.ps1', 'PCInfo_Legacy_Win7.ps1',
    'PCInfo_Legacy_XP.cmd', 'PCInfo_Legacy_XP_WMI.vbs', 'PCInfo_Sales.ps1',
    'XP_Report_HTML.vbs', 'XP_Report_BMP.vbs'
)
foreach ($file in $runtime) {
    Copy-Item -LiteralPath (Join-Path $root "src\$file") -Destination $system.FullName
}
Copy-Item -LiteralPath (Join-Path $root 'docs\CHANGELOG.md') -Destination (Join-Path $system.FullName 'CHANGELOG.txt')

Add-Type -AssemblyName System.IO.Compression.FileSystem
[IO.Compression.ZipFile]::CreateFromDirectory($folder, $archive, [IO.Compression.CompressionLevel]::Optimal, $true, [Text.Encoding]::UTF8)
Get-Item -LiteralPath $archive
