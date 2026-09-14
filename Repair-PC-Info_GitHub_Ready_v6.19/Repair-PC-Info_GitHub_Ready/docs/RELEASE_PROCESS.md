# GitHub Release 手順

## 1. 動作確認

Release 前に Windows 実機で以下を確認します。

- CMD が起動する
- 初回利用規約が表示される
- 簡易モードが完走する
- 詳細モードが必要に応じて完走する
- 主要スペック1.png が生成される
- 主要スペック2_SMART.png が生成される
- ライセンス情報.png が生成される
- Office確認で長時間停止しない
- EventDangerSignals.txt が生成される

## 2. Git 更新

```bash
git add .
git commit -m "Release v6.19"
git push origin main
```

## 3. タグ作成

```bash
git tag v6.19
git push origin v6.19
```

## 4. GitHub Release

GitHub の Releases から新しい Release を作成し、
タグ `v6.19` を指定します。

Release Asset として以下を添付します。

```text
Repair_PCInfo_UserMode_Package_v6.19.zip
```

## 5. 社員への案内

社員には **Releases の ZIP** を案内します。
`Code > Download ZIP` はソース配布なので、通常利用者向けには推奨しません。

## Release 前セキュリティ確認

- 実案件の診断結果が混入していない
- S/N / プロダクトキーが混入していない
- SMTP パスワード / APIキー / Token が入っていない
- `.env` / Credential ファイルが入っていない
- 個人情報が残っていない
