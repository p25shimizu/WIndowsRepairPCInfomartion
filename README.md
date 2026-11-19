# PC診断ツール / Windows Repair PC Information Logger

**社内利用限定 / Internal Use Only**

現在の配布版は **v6.20 Internal Preview**（2026-11-19）です。安定版の履歴は v6.19 を参照してください。

## 社員向け配布

会社用Google Driveの社員向け配布先から配布ZIPをダウンロードし、すべて展開して `PC診断ツールを起動.cmd` を開きます。詳しくは [社員向け手順](docs/README_EMPLOYEE.md) を参照してください。

| OS | 自動選択するCollector |
|---|---|
| Windows XP SP3 | CMD + VBScript / WMI。PowerShell不要 |
| Windows 7 | 既存Legacy PowerShell Collector |
| Windows 8 / 8.1 / 10 / 11 | v6.19系Modern PowerShell Collector |

自動判定できない場合はOS選択メニューが表示されます。手動で開く場合はランチャーに `/manual` を指定できます。

## 開発・配布

GitHubの `main` をソースコードの正本とします。従来のv6.19スナップショットはリポジトリ内に保持しています。

管理担当者はWindows側の作業PCで、リポジトリのルートから次を実行します。

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\distribution\Build_EmployeePackage.ps1 -OutputDirectory C:\PCInfoBuild
```

フォルダーと同名のZIPが生成されます。展開後の起動確認を行い、社内で閲覧権限が管理された会社用Google Driveへ配布ZIPを登録します。

- [変更履歴](docs/CHANGELOG.md)
- [XP・Windows 7のVMテスト](docs/LEGACY_VM_TEST.md)
- [互換性テスト記録](docs/V620_COMPATIBILITY_TEST.md)

診断結果は参考情報です。実案件の診断ログ、キー、識別情報、VMイメージをGitHubに追加しないでください。販売資料は現物と照合し、社内診断用の出力と区別してください。
