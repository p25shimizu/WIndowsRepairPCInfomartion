修理PC 情報取得ツール v6.19
=========================

【変更点】
・画像上のS/Nマスクを廃止。シリアル番号をそのまま表示します。
・メモリ表示に「総容量 / 搭載枚数 / メモリスロット」を追加。
・メモリスロットは以下を分離表示します。
  - BIOS/SMBIOS報告スロット数
  - 現在使用中のスロット数
  - 計算上の空きスロット数
・SSDの接続方式を単純なSCSI表記ではなく、
  NVMe / AHCI / RAID / Intel RST / VMD等へ可能な範囲で分類します。
・Intel Optane / Optane Memoryの文字列検出を追加しました。
・Microsoft Office / Microsoft 365の有無を判定します。
・主要スペック1.png にメモリスロット、ストレージ接続方式、
  Optane判定、Office、バッテリー情報を表示します。
・主要スペック2_SMART.png にSMART/信頼性情報を表示します。

【メモリスロット数について】
Windowsから取得する総スロット数はWin32_PhysicalMemoryArrayの
MemoryDevices、つまりBIOS/SMBIOSが報告した値です。
機種によって実装数と異なる値が返る場合があるため、
本ツールでは「SMBIOS報告値」と「実際に検出したDIMM枚数」を分けています。

【AHCI / RAIDについて】
WindowsではSATA SSDがSCSI互換デバイスとして見える場合があります。
そのため本ツールはSSD単体のInterfaceTypeをそのまま表示せず、
Get-PhysicalDiskのBusTypeとストレージコントローラー名
（AHCI / RAID / Intel RST / VMD）を合わせて判定します。

【Optaneについて】
モデル名、PhysicalDisk名、ストレージコントローラー名に
Optane表記がある場合に検出します。
OEM構成によっては判別できない場合があります。

【Office判定】
Microsoft 365 / Office Click-to-Runのレジストリ情報と、
インストール済み製品情報から判定します。

【使い方】
1. Run_PCInfo_UserMode.cmd をダブルクリックします。
2. 案件番号を入力します。
3. 通常モードまたは詳細モードを選択します。
4. デスクトップの案件フォルダにログ・HTML・PNGが生成されます。

管理者権限への昇格は要求しません。
取得できない項目は可能な範囲でスキップします。


【v6.1 メモリスロット判定の変更】
SMBIOSのMemoryDevices値を、そのまま「物理スロット数」として表示する方式を廃止しました。

以下を分けて表示します。
・増設可否
・物理メモリスロット数
・検出メモリモジュール数
・空きスロット数
・SMBIOS MemoryDevices（参考値）
・判定理由
・判定信頼度

ThinkPad X1 Carbon / X1 Yoga / X1 Nano / X1 Fold は、
オンボードメモリ機として「増設不可 / 物理スロット0」と判定します。

その他の機種については、
DeviceLocator等からDIMM/SO-DIMMスロットを検出できた場合のみ
「増設可能」とし、確定できない場合は「要確認」にします。
これによりSMBIOS値だけを見て誤って「2スロット」等と表示するのを避けます。


【v6.19 追加修正】
・ボリューム情報に C: / D: 等のドライブ文字、ラベル、総容量、使用量、空き容量を表示。
・GPU名だけでなくドライババージョンも表示。
・ウイルス対策ソフトの有無を SecurityCenter2 から検出。
・バッテリーは設計容量、満充電容量、現在容量、Healthを表示。
・CPUは概算のPassMarkスコア目安を表示。
  ※ オフライン対応のため、代表CPUのみ内蔵マップで近似表示します。


【v6.19 追加修正】
・バッテリーの寿命目安を「満充電容量 ÷ 設計容量 × 100」で明示。
  例：寿命目安 84.9% / 劣化率 15.1%
・主要スペック3_CPU_GPU_RAM.png を追加。
  CPU / PassMark目安 / GPU / GPUドライバ / RAM容量 / DIMM構成 /
  メモリ増設可否にフォーカスした画像です。
・SMART詳細を強化。
  Get-StorageReliabilityCounter に加え、取得可能なSATA/ATA機器では
  WMIのSMART VendorSpecificから属性ID、Current、Worst、Threshold、
  RawValue、FlagsをSMARTログへ出力します。
・SMART画像には主要属性（Reallocated Sector、Power-On Hours、
  Pending Sector、Temperature、SSD Life Left等）を可能な範囲で追記します。

※ NVMeはATA SMART属性方式ではないため、Windows標準APIから取得できる
   Health / Temperature / Wear / PowerOnHours等を優先表示します。
※ SSD/NVMeコントローラーやOEMドライバにより、詳細SMARTが取得できない場合があります。


【v6.19 ライセンス情報】
WindowsとOffice/Microsoft 365のライセンス情報を、
主要スペックとは別のファイルへ出力します。

追加生成物:
・No.案件番号-License.txt
・ライセンス情報.png

Windows:
・ライセンス認証状態
・ライセンスチャネル
・プロダクトキー末尾5文字
・ライセンス説明

Office/Microsoft 365:
・インストール製品
・ライセンス認証状態（取得可能な場合）
・ライセンスチャネル
・プロダクトキー末尾5文字（取得可能な場合）

セキュリティ上、完全なWindows/Officeプロダクトキーは画像・ログに出しません。
OEM/デジタルライセンス/Microsoft 365サブスクリプション等では、
キー自体が存在しない、またはWindows標準APIから取得できない場合があります。


【v6.19 主要スペック1 バッテリー表示】
主要スペック1.png のバッテリー欄を簡素化しました。

表示項目:
・バッテリー型番 / DeviceName
・寿命目安（満充電容量 ÷ 設計容量 × 100）
・満充電容量

詳細な設計容量、現在容量、メーカー、劣化率等は
PCInfo.txt / battery-report.html 側に残します。

バッテリー型番は BatteryStaticData.DeviceName を優先し、
取得できない場合は Win32_Battery.Name / DeviceID を使用します。
OEMによっては型番ではなく汎用名が返る場合があります。


【v6.19 Firmware / Secure Boot / TPM】
別途 No.案件番号-FirmwareSecurity.txt を生成します。

出力内容:
・UEFI / Legacy BIOS
・Secure Boot 有効 / 無効 / 非対応
・TPM搭載有無
・TPM Ready / Enabled / Activated
・TPM仕様バージョン
・TPMメーカー
・Windows 11主要要件チェック
  - UEFI
  - Secure Boot対応
  - TPM 2.0

【A4画像】
主要スペック1.png
主要スペック2_SMART.png
主要スペック3_CPU_GPU_RAM.png
ライセンス情報.png

上記の画像はすべて A4縦 300dpi（2480 x 3508 px）で生成します。


【v6.19 画像レイアウト修正】
A4/300dpi画像で文字が重なっていた原因は、
300dpi画像上でポイント指定フォントが大きく展開されていたことです。

v6.19では、
・フォントサイズをPixel単位で固定
・文字列を自動折り返し
・実際の文字高さを測定して次行位置を決定
・A4 1ページを超える場合は重ねずに注意書きを表示
としました。

【完全ライセンスキー】
Windows:
UEFI/ファームウェアに埋め込まれたOEM OA3キー、またはWindowsが保持する
BackupProductKeyDefaultを取得できた場合は完全キーを表示します。
デジタルライセンス等では完全キーが存在しない/取得できないことがあります。

Office / Microsoft 365:
現在のClick-to-Run/Microsoft 365環境では、完全なプロダクトキーを
Windows標準APIから復元できない場合が多いため、取得できない場合は
その旨を明記します。認証状態・製品名・キー末尾5文字は従来通り出力します。


【v6.19 画像生成不具合の修正】
v6.7のA4画像描画処理で RectangleF / Font 等の生成方法に互換性上の問題があり、
環境によってNew-InfoPngが例外終了して画像が作成されない可能性がありました。

v6.19では System.Drawing オブジェクトを .NET の ::new() で明示生成する方式へ変更。
A4縦 300dpi、Pixel単位フォント、自動折り返しは維持しています。

画像生成に失敗した場合は案件フォルダへ
ImageGeneration_Error.txt
を生成し、原因を確認できるようにしました。


【v6.19 画像調整】
・主要スペック1.png のバッテリー欄で、寿命を明記する表現へ統一。
  表示:
  - 型番
  - 寿命
  - 満充電容量

・主要スペック3_CPU_GPU_RAM.png を簡素化。
  表示:
  - CPU名
  - PassMark目安
  - コア / スレッド
  - RAM総容量
  - 搭載枚数
  - 増設可否
  - GPU名
  - GPUドライバ


【v6.19 安定化】
v6.9で実行中に落ちるケースに対応するため、画像描画処理を簡素化しました。

・MeasureString / RectangleF を使わない
・Windows PowerShell 5.1で扱いやすいSystem.Drawing構成
・A4縦 300dpiは維持
・長文は簡易自動折り返し
・CPU/GPU/RAM画像はさらに簡素化

またCMDは必ず最後にpauseするよう変更し、
実行フォルダへ Launcher_LastRun.log を保存します。

画像生成だけ失敗した場合:
ImageGeneration_Error.txt

スクリプト全体が停止した場合:
Launcher_LastRun.log

を確認してください。


【v6.19 Event Viewer 危険信号】
別テキスト:
No.案件番号-EventDangerSignals.txt

過去30日のSystem/Applicationイベントから修理時に優先確認したい
「危険信号」を抽出します。

主な監視対象:
・CRITICAL_PROCESS_DIED / BugCheck 0xEF
・BugCheck / BSOD
・Kernel-Power Event ID 41
・WHEA-Logger（CPU / RAM / PCIe等のハードウェアエラー）
・Disk / StorAHCI / StorNVMe / Intel RST / NTFS / volmgr
・EventLog 6008（予期しないシャットダウン）
・GPU / Displayドライバ異常
・csrss.exe / wininit.exe / winlogon.exe / services.exe /
  lsass.exe / smss.exe 等の重要Windowsプロセス異常

各イベントについて、
日時 / 重要度 / カテゴリ / Provider / Event ID / 判定理由 /
イベントメッセージ
を保存します。

これは故障を自動確定するものではなく、
修理担当者が優先調査すべきイベントを抽出する診断補助です。


【v6.19 変更履歴ファイル】
パッケージ内に CHANGELOG.txt を追加しました。

また、ツール実行時には案件フォルダへ
Tool_CHANGELOG.txt
として同じ変更履歴をコピーします。

これにより、どの機能がどのバージョンで追加・修正されたかを
案件ログと一緒に保存できます。


【v6.19 画像表記の調整】
・主要スペック1.png のバッテリー欄に、寿命計算を明記。
  表示例:
  - 寿命: 84.9 %（劣化 15.1 %）
  - 寿命計算: 38200 / 45000 mWh = 84.9 %

・主要スペック3_CPU_GPU_RAM.png のRAM欄に注意書きを追加。
  - 増設可能表示でも交換可を保証しない
  - 公式情報および欧米レビュアー情報の確認が必要


【v6.19 初回利用規約】
初回起動時に利用規約 / 注意事項を表示します。

・取得結果は参考情報であり、現物・目視・BIOS/UEFI・公式情報での確認が必要
・自動判定だけで修理判断、部品発注、顧客説明等を確定しない
・Windows / Officeライセンス情報やプロダクトキーは機密情報として扱う
・ツールおよび生成物の利用は社内業務に限定
・社外配布、再配布、公開、転載、個人利用、第三者提供を禁止
・社外提示前にS/Nやプロダクトキー等の機密情報混入を確認
・改変版 / 派生版の社外持ち出しを禁止

同意情報:
%LOCALAPPDATA%\Repair_PCInfo_UserMode\TermsAccepted.txt

同一ユーザー・同一Windows環境では、同じ規約バージョンは
初回のみ表示します。


【v6.19 画像内フッター強化】
各PNG画像のフッターに、以下を表示するように変更しました。
・取得日時
・画像出力日時
・ツール名 / バージョン

表示例:
取得日時: 2026/08/14 10:25:12 / 画像出力: 2026/08/14 10:25:13 / Repair PC Information Logger v6.19


【v6.19 バッテリー表示 / Office高速化】

■ 主要スペック1.png - バッテリー
・型番
・設計容量
・満充電容量
・現在容量
・寿命
・寿命計算
・劣化率
・充電 / 放電 / AC接続等の状態
・サイクル回数（取得可能な機種のみ）

寿命は、
満充電容量 ÷ 設計容量 × 100
で算出します。

※ 現在容量 / サイクル回数 / 状態は機種やメーカー実装により取得できない場合があります。

■ Office高速化
Officeライセンス確認は速度優先へ変更しました。

・SoftwareLicensingProductの全件走査を原則行わない
・Click-to-Runレジストリを優先
・取れなければアンインストール情報のみ確認
・取得できない場合は「未走査 / 取得省略」として続行

Office判定でPC情報取得全体が長時間停止しない方針です。


【v6.19 初回利用規約の復旧】
v6.16で初回利用規約ブロックが欠落していたため復旧しました。

初回起動時:
・社内利用規約 / 注意事項を表示
・Yで同意した場合のみ続行
・同意済み情報は以下へ保存
  %LOCALAPPDATA%\Repair_PCInfo_UserMode\TermsAccepted.txt

保存する情報:
・TermsVersion
・AcceptedAt
・Accepted=True

氏名 / Windowsユーザー名 / コンピューター名は保存しません。


【規約バージョン 1.1】
既に旧版で規約同意済みのPCでも、v6.19では規約バージョンを1.1へ更新したため、
初回起動時に再度規約画面が表示されます。
1.1への同意後は次回以降スキップされます。


【v6.19 Office認証走査の停止 / 高速化】

Office / Microsoft 365について、実行時間を優先し、
認証キー・認証状態を探す走査を原則停止しました。

実施する処理:
・Click-to-Runレジストリからインストール有無 / 製品 / バージョンを確認
・必要時のみアンインストールレジストリを確認

実施しない処理:
・SoftwareLicensingProductのOffice全件走査
・ospp.vbs / cscriptによる認証情報探索
・完全プロダクトキー探索

表示:
・Office検出時: 認証走査省略
・Office未検出時: 未検出

Windowsライセンス確認は従来通りです。


【v6.19 主要スペック1 カテゴリ再編 / 主要スペック3廃止】

主要スペック1.png を以下のカテゴリへ整理しました。
・本体
・CPU
・メモリ
・ストレージ
・ボリューム
・GPU
・バッテリー
・OS / セキュリティ / Office

本体:
・メーカー
・モデル名
・S/N
・DELL: Service Tag / Express Service Code
・HP: Product Number / System SKU

メモリ:
増設可能と表示されても交換可能とは限らない旨と、
メーカー公式情報 / 保守資料 / 欧米レビュアー等の分解情報を
確認すべき旨を画像へ記載します。

主要スペック3_CPU_GPU_RAM.png は廃止しました。
CPU / RAM / GPUは主要スペック1へ統合しています。
