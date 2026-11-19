# Windows XP / Windows 7 仮想環境テスト手順

更新日: 2026-11-19  
対象バージョン: v6.20 Compatibility Preview

## 方針

Windows XP / Windows 7のLegacy互換性確認は、**仮想環境上で実施する**。

GitHub ActionsはCMD / PowerShell構文・分岐の継続テストに使用し、
Legacy OS固有のWMI/API/画像生成についてはWindows XP / Windows 7 VM内で確認する。

VMイメージ、Windows ISO、プロダクトキー、スナップショット等はGitHubへ保存しない。

## 対象VM

最低限、以下をテスト対象とする。

| ID | OS | PowerShell | 用途 |
|---|---|---|---|
| VM-XP | Windows XP SP3 | 2.0 | XP Legacy互換 |
| VM-W7 | Windows 7 SP1 | 2.0以上 | Windows 7 Legacy互換 |

両OS対応を正式に表記する場合は、**両方で合格**することを完成条件とする。

## VMの推奨運用

- テスト開始前にクリーンスナップショットを作成
- XP / 7は原則としてインターネットへ直接接続しない
- ファイル受け渡しはISO、共有フォルダ、ホストオンリー等を使用
- テスト終了後にスナップショットへ戻せる状態を維持
- 実案件データや顧客情報をLegacy VMへ持ち込まない

使用するハイパーバイザーは固定しない。
VirtualBox / VMware / Hyper-V / QEMU等、対象OSを安定して動かせる環境を使用する。

## テスト前準備

1. リポジトリの最新版をVMへコピー
2. XPの場合はWindows PowerShell 2.0が起動することを確認
3. `tests\legacy\Run_VM_Test.cmd` を実行
4. デスクトップに生成された `Legacy_VM_Preflight_YYYYMMDD_HHMMSS` を確認

Preflightは以下を確認する。

- OS / Service Pack
- PowerShell
- 必須ファイル
- 主要WMIクラス
- Battery / SMART WMI
- Security Center
- WindowsライセンスWMI
- System Event Log
- System.Drawing PNG生成
- msinfo32 / dxdiag存在確認

## 本体テスト

Preflight後、以下を実施する。

1. `launcher\Run_PCInfo_UserMode.cmd` を起動
2. CMDのOS自動判定が正しいことを確認
3. `Y` を入力して自動判定を採用
4. 案件番号はテスト用文字列を使用
   - XP: `VM-XP`
   - Windows 7: `VM-W7`
5. 通常モードを実行
6. 完走と出力ファイルを確認
7. 再度起動し、詳細モードを実行
8. 完走と追加出力を確認
9. CMDで `N` を選択し、手動OS指定でもLegacyへ分岐することを確認

## 合格基準

### 必須

- CMDが起動する
- OS名が表示される
- XP / 7でLegacy Collectorへ分岐する
- 案件番号を入力できる
- 通常モードが最後まで終了する
- 詳細モードが最後まで終了する
- PCInfoテキストが生成される
- SMARTレポートが生成される
- Firmware/Securityレポートが生成される
- Event Danger Signalsが生成される
- Licenseレポートが生成される
- `主要スペック1.png` が生成される
- `主要スペック2_SMART.png` が生成される
- `ライセンス情報.png` が生成される

### 取得不能を許容するもの

VMでは仮想ハードウェアの都合により以下が取得できないことがある。

- バッテリー
- SMART
- TPM
- ウイルス対策製品
- OEM固有情報

これらは**取得不可と表示され、ツール全体が停止しなければ合格候補**とする。

## 不合格条件

- PowerShell構文エラー
- CMDが即終了する
- OS分岐を誤る
- WMI取得不能でスクリプト全体が停止する
- System.Drawingエラーでツール全体が停止する
- 出力フォルダを作成できない
- 通常/詳細モードのいずれかが完走しない

## 記録

VMテスト実施後、`docs/V620_COMPATIBILITY_TEST.md` に以下を追記する。

- 実施日
- ハイパーバイザー
- VM OS / Edition / Service Pack
- 32bit / 64bit
- PowerShellバージョン
- 通常モード結果
- 詳細モード結果
- 取得できなかった項目
- 発見した不具合
- 修正コミット
- 再テスト結果

診断結果そのものには識別情報が含まれる可能性があるため、原則としてGitHubへコミットしない。
