# PC診断ツール / Windows Repair PC Information Logger

> ⚠️ **INTERNAL USE ONLY / 社内利用限定**

Windows PC の診断・修理・検品・リプレース業務を補助するための社内向け情報取得ツールです。

## バージョン

- **安定版:** v6.19
- **開発版:** v6.20 Compatibility Preview
- **更新日:** 2026-11-17

v6.20では、GitHub運用に加えて **Windows XP / Windows 7互換モード** の実装を開始しました。

> v6.20 Legacyは実機検証前です。Windows XP SP3 / Windows 7 SP1で確認後、安定版として扱います。

## 対応OS

| OS | 使用モード | 状態 |
|---|---|---|
| Windows 10 / 11 | Modern | 現行機能 |
| Windows 8 / 8.1 | Modern | 原則Modern |
| Windows 7 | Legacy | v6.20で追加・要実機検証 |
| Windows XP | Legacy | PowerShell 2.0導入済み環境のみ・要実機検証 |

起動時にOSバージョンを自動判定し、XP / Vista / 7ではLegacyコレクタ、それ以降ではModernコレクタを使用します。

## Windows XPについて

Windows XPにはPowerShellが標準搭載されていないため、**Windows PowerShell 2.0 / WMF 2.0が事前導入済み**であることを前提とします。

PowerShellが見つからない場合は、ランチャーが要件を表示して安全に終了します。

## 社員向け：使い方

正式配布版では、GitHubのソースコードではなく **Releasesの配布ZIP** を利用します。

1. GitHubの **Releases** を開く
2. 最新の `PC診断ツール_vX.XX.zip` をダウンロード
3. ZIPを展開
4. `PC診断ツールを起動.cmd` をダブルクリック
5. OSは自動判定
6. 案件番号を入力
7. 通常モード / 詳細モードを選択
8. デスクトップの診断結果フォルダを確認

## Legacyモードで取得する主な情報

- メーカー / モデル / S/N / UUID
- OS / Service Pack
- CPU
- RAM / SMBIOSメモリ情報
- HDD / SSD / ボリューム
- GPU / ドライバ
- BIOS / マザーボード
- PnPエラー
- Security Center経由のウイルス対策情報
- Officeインストール情報
- Windowsライセンス状態
- バッテリー情報
- WMI SMART Failure Predict
- Event Log危険信号
- `msinfo32` / `dxdiag`（詳細モード）
- 主要スペック1.png
- 主要スペック2_SMART.png
- ライセンス情報.png

## Legacyモードの制約

XP/7には現行Windowsの一部API・機能が存在しません。そのため以下は代替取得または非対応表示になります。

- `Get-PhysicalDisk` / `Get-StorageReliabilityCounter` は使用しない
- Secure BootはXP/7ではOS非対応として表示
- TPMはWindows 7で `Win32_Tpm` が利用できる場合のみ取得
- NVMe / RAID / AHCIの接続方式判定精度はModernより低い
- `powercfg /batteryreport` はXP/7では生成しない
- SMARTはコントローラー / USB変換 / OEMドライバにより取得不能な場合あり

**取得不可＝故障ではありません。**

## 通常モード / 詳細モード

### 通常モード

通常の検品・リプレース・一次診断向けです。

### 詳細モード

通常モードに加えて、ドライバ、HotFix、追加イベント情報、`msinfo32`、`dxdiag` 等を取得します。

## セキュリティ

診断結果にはS/N、Windowsプロダクトキー、ネットワーク情報、イベントログ等が含まれる可能性があります。

**実案件の診断結果や案件フォルダをGitHubへコミットしないでください。**

SMTP / API等を追加する場合も、パスワード・APIキー・アクセストークン等をソースコードへ直書きしません。

## GitHub運用

このリポジトリでは、ユーザー指示により当面 **mainへ直接コミット**して更新します。

正式配布時は、動作確認後にタグとGitHub Releaseを作成し、社員にはRelease AssetのZIPを案内します。

## 重要事項

本ツールの取得・判定結果は**参考情報**です。

修理判断、部品発注、顧客説明、保証判断等を確定する場合は、現物、BIOS/UEFI、メーカー公式情報、保守資料等で最終確認してください。

本ツール、本リポジトリ、生成されたログ・画像・レポート等は**社内業務限定**です。
