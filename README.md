# CmdKana

macOSで左右のCommandキーを単独で押して離した際に、英数/かなの入力ソースを切り替えるメニューバー常駐アプリです。[cmd-eikana](https://github.com/iMasanari/cmd-eikana)の後継として、最小限の機能のみを実装しています。

## 機能

- **左Command** を単独で押して離す → **英数** に切り替え
- **右Command** を単独で押して離す → **かな** に切り替え
- メニューバーに常駐（Dockには表示されません）
- ログイン時の自動起動に対応
- 設定ウィンドウで動作状態（権限・キー監視）の確認とキー動作テストが可能
- アプリ内自動アップデート（Sparkle）

Cmd+C、Cmd+V などのショートカット操作時には入力ソースの切り替えは発生しません。

## 動作要件

- macOS 14 (Sonoma) 以降
- Accessibility権限（初回起動時にシステムが許可を求めます）

## インストール

### Homebrew（推奨）

```sh
brew install --cask masakichi41/tap/cmdkana
```

### 手動インストール

1. [Releases](https://github.com/masakichi41/CmdKana/releases) から最新の `CmdKana-x.y.z.dmg` をダウンロード
2. DMG を開き、`CmdKana.app` を「アプリケーション」フォルダにドラッグ
3. 初回起動時に Accessibility 権限を許可（下記「使い方」を参照）

配布する DMG は Apple の公証（notarization）済みのため、警告なしで起動できます。

## ビルド（開発者向け）

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

- **Settings…** — 設定ウィンドウを開く
- **Check for Updates…** — 手動で更新を確認
- **Quit CmdKana** — アプリの終了

設定ウィンドウ（**Settings…**）では、Accessibility 権限やキー監視の状態、左右 Command キーの動作テスト、ログイン時起動、バージョン情報を確認・変更できます。

## アップデート

CmdKana はアプリ内アップデート（Sparkle）に対応しています。

- メニューバーの <kbd>&#x2318;</kbd> アイコン → **Check for Updates…** で手動確認できます。新しいバージョンがあればワンクリックで更新できます。
- 既定で定期的に更新を確認し、新版があれば通知します（設定画面の **About** で自動チェックの切り替えが可能）。
- Homebrew でインストールした場合は `brew upgrade --cask cmdkana` でも更新できます。

## アンインストール

Homebrew でインストールした場合:

```sh
brew uninstall --zap --cask cmdkana
```

`--zap` を付けると設定ファイル（`~/Library/Preferences/net.ma41.CmdKana.plist`）も一緒に削除されます。

手動インストールの場合は `CmdKana.app` を削除してください。設定を完全に消すには上記の plist も削除します。あわせて、システム設定 → プライバシーとセキュリティ → アクセシビリティ のリストからも手動で削除してください。

## 謝辞

[cmd-eikana](https://github.com/iMasanari/cmd-eikana) — 本プロジェクトの参考元

## ライセンス

MIT License
