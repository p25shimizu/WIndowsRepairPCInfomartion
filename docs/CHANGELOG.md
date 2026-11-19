# 変更履歴

## v6.20 Internal Preview（2026-11-19）

社員が各OSのCollectorを意識せず、会社用Google Driveから展開して使える構成へ統合した。

- XPのPowerShell前提を廃止し、CMDとVBScript/WMIによる専用Collectorへ移行。
- 社員向けCMDがOSを自動判定。XP、Windows 7、Windows 8以降へ分岐し、不明時は手動選択。
- Windows 7のLegacy診断、v6.19のModern診断とPNG出力を引き継ぎ、主要ログ名を日本語に統一。
- 主要スペックHTML、出品用情報、販売前チェックを出力。XPは販売用BMPも出力。
- XPのIP情報、SecurityCenter、Systemログを取得。取得不能はレポートに記録して続行。
- GitHubを開発ソースの正本、会社用Google Driveを社員向け配布先とし、社内向けZIPを再生成できる手順を追加。
