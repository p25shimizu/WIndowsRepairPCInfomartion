# Repair PC Information Logger

> ⚠️ **INTERNAL USE ONLY / 社内利用限定**

Windows PC の診断・修理・検品・リプレース業務を補助するための社内向け情報取得ツールです。

## 最新版

現在のソース: **v6.19**

社員への配布は、このリポジトリのソースを直接取得させるのではなく、
**GitHub Releases に登録した ZIP** を利用する運用を推奨します。

## 重要事項

- 本ツールの取得・判定結果は **参考情報** です。
- 実際の仕様、部品構成、増設可否、交換可否、型番、容量、ライセンス状態等は、
  **現物確認 / 目視 / BIOS・UEFI / メーカー公式情報 / 保守資料** で最終確認してください。
- 本ツールだけを根拠に、修理判断・部品発注・顧客説明・保証判断を確定しないでください。
- Windows / Office のライセンス情報、シリアル番号、ネットワーク情報等は機密情報として扱ってください。
- 本リポジトリおよび生成物の利用は **社内業務に限定** します。

## 社員向けの使い方

1. GitHub の **Releases** を開く
2. 最新の `Repair_PCInfo_UserMode_Package_vX.X.zip` をダウンロード
3. ZIP を展開
4. `Run_PCInfo_UserMode.cmd` を実行
5. 初回のみ利用規約を確認して同意
6. 案件番号を入力
7. 簡易モード / 詳細モードを選択
8. デスクトップに生成された案件フォルダを確認

## v6.19 の主な出力

### 主要スペック1
カテゴリ単位で表示します。

- 本体
- CPU
- メモリ
- ストレージ
- ボリューム
- GPU
- バッテリー
- OS / セキュリティ / Office

### 主要スペック2
SMART / ストレージ状態

### ライセンス情報
Windows ライセンス情報を中心に出力します。
Office は高速化のため、詳細な認証キー走査を原則行いません。

### その他
- Firmware / Secure Boot / TPM
- Event Viewer 危険信号
- バッテリー情報
- 診断テキスト
- CHANGELOG

## 簡易モードと詳細モード

### 簡易モード
通常の検品・リプレース・一次診断向けです。

### 詳細モード
障害解析向けです。簡易モードに加えて、
ドライバ、HotFix、追加イベント情報、`msinfo32`、`dxdiag` 等を取得します。

## セキュリティ

診断結果には以下が含まれる可能性があります。

- S/N
- Windows プロダクトキー
- Office 関連情報
- ネットワーク情報
- イベントログ

そのため、**案件フォルダや診断結果を GitHub にコミットしないでください。**

また、今後 SMTP / API / Credential を実装する場合も、
パスワード、APIキー、トークン等をソースへ直書きしないでください。

## リポジトリ構成

```text
Repair-PC-Info/
├─ README.md
├─ CHANGELOG.md
├─ INTERNAL_USE_POLICY.md
├─ .gitignore
├─ src/
│  └─ Repair_PCInfo_UserMode.ps1
├─ launcher/
│  └─ Run_PCInfo_UserMode.cmd
├─ docs/
│  ├─ RELEASE_PROCESS.md
│  ├─ README_legacy.txt
│  ├─ CHANGELOG_legacy.txt
│  └─ INTERNAL_USE_POLICY_legacy.txt
└─ release/
   └─ Repair_PCInfo_UserMode_Package_v6.19.zip
```

## ライセンス / 利用条件

一般公開用 OSS ライセンスではありません。
利用条件は `INTERNAL_USE_POLICY.md` を参照してください。
