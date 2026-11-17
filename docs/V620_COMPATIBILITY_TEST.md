# v6.20 Compatibility Test Record

更新日: 2026-11-17

## 目的

Windows XP / Windows 7互換対応を追加したv6.20について、
GitHub ActionsのWindows runnerを用いてCMD / PowerShellの基本動作を確認する。

## テスト環境

- GitHub Actions
- windows-2022
- Windows PowerShell 5.1
- 実際の `cmd.exe` を使用

## 検証済み

### PowerShell

- `Repair_PCInfo_Bootstrap.ps1` の構文解析: PASS
- `Repair_PCInfo_Legacy.ps1` の構文解析: PASS
- Legacyコレクタに以下のModern依存コマンドが混入していないこと: PASS
  - Get-CimInstance
  - Get-PhysicalDisk
  - Get-StorageReliabilityCounter
  - Get-WinEvent
  - $PSScriptRoot
  - [PSCustomObject]

### CMD / OS分岐

- 自動判定 → Modern: PASS
- 手動 Windows XP → Legacy: PASS
- 手動 Windows 11 → Modern: PASS
- CMDラベル参照整合性: PASS

成功Run:

- Workflow: v6.20 compatibility smoke test
- Run ID: 44006000107
- Result: success

## テスト中に発見・修正した問題

### OS表示が Unknown Windows になる

初回のWindows runner試験で、分岐自体は成功したがCMDのOS表示が
`Unknown Windows` となった。

原因候補:
- `for /f` 内から引用符付きPowerShellパスを呼び出す構成

修正:
- PowerShellのOS名取得結果を一時ファイルへ出力
- CMDの `set /p` で読み込む方式へ変更

修正後、Windows runnerで以下を確認した。

```text
Detected OS: Microsoft Windows Server 2022 Datacenter
```

## 未検証

以下はGitHub Actionsでは検証できないため実機確認が必要。

- Windows XP SP3上でWindows PowerShell 2.0を使用した完走
- Windows 7 SP1 / PowerShell 2.0での完走
- XP実機でのWMIクラス取得状態
- Windows 7実機でのSoftwareLicensingProduct取得
- XP / 7実機でのSystem.Drawing PNG生成
- XP / 7の実機SMART取得
- XP / 7でのSecurity Center AV情報
- XP / 7でのmsinfo32 / dxdiag詳細モード
- 各メーカーOEM機固有のWMI差異

## 判定

現時点のv6.20は:

**Compatibility Preview / 実機検証前**

とする。

XP SP3およびWindows 7 SP1で診断完走を確認後、
Legacy互換機能を安定版扱いへ移行する。
