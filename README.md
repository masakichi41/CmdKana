# CmdKana

macOSで左右のCommandキーを単独で押して離した際に、英数/かなの入力ソースを切り替えるメニューバー常駐アプリです。[cmd-eikana](https://github.com/iMasanari/cmd-eikana)の後継として、最小限の機能のみを実装しています。

## 機能

- **左Command** を単独で押して離す → **英数** に切り替え
- **右Command** を単独で押して離す → **かな** に切り替え
- メニューバーに常駐（Dockには表示されません）
- ログイン時の自動起動に対応

Cmd+C、Cmd+V などのショートカット操作時には入力ソースの切り替えは発生しません。

## 動作要件

- macOS 13 (Ventura) 以降
- Accessibility権限（初回起動時にシステムが許可を求めます）

## ビルド

```bash
xcodebuild -project CmdKana.xcodeproj -scheme CmdKana build
```

ビルド後のアプリは `build/Debug/CmdKana.app` に出力されます。Xcodeで直接開いてビルド・実行することもできます。

## 使い方

### 初回起動時

1. CmdKana.appを起動します
2. macOSのAccessibility権限ダイアログが表示されます
3. システム設定 > プライバシーとセキュリティ > アクセシビリティ で CmdKana を許可してください
4. 権限が付与されると自動的にキー監視が開始されます

### 通常の使い方

メニューバーの <kbd>&#x2318;</kbd> アイコンから以下の操作ができます:

- **Start at Login** — ログイン時に自動起動するかの切り替え
- **Quit CmdKana** — アプリの終了

## アンインストール

CmdKana.appを削除してください。設定ファイルは作成されないため、アプリの削除のみで完了します。

## 謝辞

[cmd-eikana](https://github.com/iMasanari/cmd-eikana) — 本プロジェクトの参考元

## ライセンス

MIT License
