# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

CmdKanaは、macOSで左右のCommandキーを単独で押して離した際に、英数/かなの入力ソースを切り替えるメニューバー常駐アプリ。cmd-eikana の後継として、最小限の機能のみを実装する。

- **左Cmd** (keyCode 55) → 英数 (keyCode 102)
- **右Cmd** (keyCode 54) → かな (keyCode 104)

## ビルド・実行

```bash
# ビルド
xcodebuild -project CmdKana.xcodeproj -scheme CmdKana build

# ビルド＋実行（Debugビルド）
xcodebuild -project CmdKana.xcodeproj -scheme CmdKana build && open ./build/Debug/CmdKana.app

# クリーンビルド
xcodebuild -project CmdKana.xcodeproj -scheme CmdKana clean build
```

Xcode (26.2+) でも直接開いてビルド・実行可能。

## アーキテクチャ

### ファイル構成

| ファイル | 役割 |
|---------|------|
| `CmdKana/CmdKanaApp.swift` | アプリエントリポイント。`MenuBarExtra`でメニューバーUI、`NSApplicationDelegateAdaptor`でライフサイクル管理 |
| `CmdKana/KeyInterceptor.swift` | コアロジック。CGEvent tapでキーボードイベント監視、modifier-only検出、合成キーイベント送信 |
| `CmdKana/AccessibilityManager.swift` | `AXIsProcessTrustedWithOptions`によるAccessibility権限チェック・プロンプト・ポーリング |

### modifier-only検出アルゴリズム

Cmdキーが「他のキーを押さずに単独で押して離された」ことを検出する状態機械：

1. `flagsChanged`イベントでCmd押下検知 → `pendingKeyCode`にkeyCodeを記録
2. `keyDown`/`keyUp`（通常キー入力） → `pendingKeyCode = nil`（Cmd+Cなどのショートカット使用を検知）
3. マウスイベント（クリック、スクロール等） → `pendingKeyCode = nil`
4. `flagsChanged`イベントでCmd解放検知 → `pendingKeyCode`が一致すれば合成キー送信

### 主要API

| API | 用途 |
|-----|------|
| `CGEvent.tapCreate(tap: .cgSessionEventTap)` | システム全体のキーボードイベント監視 |
| `CGEvent.post(tap: .cghidEventTap)` | 合成キーイベント送信（keyCode 102/104） |
| `AXIsProcessTrustedWithOptions()` | Accessibility権限チェック・プロンプト |
| `MenuBarExtra` | メニューバーUI (macOS 13+) |
| `SMAppService.mainApp` | ログイン時起動管理 (macOS 13+) |

## 技術的制約

### App Sandbox無効

CGEvent tapはApp Sandboxと非互換。`ENABLE_APP_SANDBOX = NO` が必須。Mac App Storeでの配布は不可（直接配布、Homebrew等で対応）。Hardened Runtimeは有効のまま維持（公証に必要）。

### Accessibility権限必須

初回起動時にmacOSのAccessibility権限ダイアログが表示される。ユーザーがシステム設定で許可するまで、アプリはポーリングで待機する。

### LSUIElement

`INFOPLIST_KEY_LSUIElement = YES` によりDockに表示せず、メニューバーのみに常駐する。

## キーコード定数

| 定数名 | 値 | 意味 |
|--------|-----|------|
| `kLeftCommand` | 55 | 左Commandキー |
| `kRightCommand` | 54 | 右Commandキー |
| `kEisuuKeyCode` | 102 | 英数キー |
| `kKanaKeyCode` | 104 | かなキー |
