# v6.20 Compatibility Test Record

更新日: 2026-11-19

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

以下はGitHub Actionsでは検証できないため、Windows XP / Windows 7の仮想環境で確認する。

- Windows XP SP3 VM上でWindows PowerShell 2.0を使用した完走
- Windows 7 SP1 VM / PowerShell 2.0以上での完走
- XP VMでのWMIクラス取得状態
- Windows 7 VMでのSoftwareLicensingProduct取得
- XP / 7 VMでのSystem.Drawing PNG生成
- XP / 7 VMでのSMART取得
- XP / 7 VMでのSecurity Center AV情報
- XP / 7 VMでのmsinfo32 / dxdiag詳細モード
- VMでは再現できない各メーカーOEM機固有のWMI差異は別途要確認

## 判定

現時点のv6.20は:

**Compatibility Preview / VM検証前**

とする。

XP SP3 VMおよびWindows 7 SP1 VMで診断完走を確認後、
Legacy互換機能を安定版扱いへ移行する。


## 2026-11-19 テスト方針変更

Legacy互換性テストは、実機ではなく仮想環境を標準テスト基盤とする。

追加したテスト資材:

- `tests/legacy/Legacy_VM_Preflight.ps1`
- `tests/legacy/Run_VM_Test.cmd`
- `docs/LEGACY_VM_TEST.md`

Windows XP / Windows 7の両対応を正式表記する場合は、両VMで通常モード・詳細モードが完走することを合格条件とする。
