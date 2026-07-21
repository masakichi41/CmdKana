//
//  AppStatus.swift
//  CmdKana
//

import Foundation

/// 直近に送出した入力ソース切り替え。設定画面の動作テスト表示に使う。
enum InputSwitch: Equatable {
    case eisuu  // 左Cmd → 英数
    case kana   // 右Cmd → かな
}

/// アプリの稼働状態を集約する診断モデル。
/// `AccessibilityManager`（権限）と `KeyInterceptor`（tap稼働・検出）が更新し、
/// `SettingsView` が観測して表示する単一の真実源。
@Observable
final class AppStatus {
    /// Accessibility権限の現在値。`AccessibilityManager` が継続的に更新する。
    var accessibilityTrusted: Bool = false

    /// CGEvent tapが稼働中か。`KeyInterceptor.start()` の成否で更新する。
    var interceptorRunning: Bool = false

    /// 直近に送出した切り替え（動作テストの可視化用）。
    var lastSwitch: InputSwitch? = nil

    /// `lastSwitch` を記録した時刻。
    var lastSwitchAt: Date? = nil

    /// 動作テスト表示を更新する。`KeyInterceptor` が合成キー送出時に呼ぶ。
    func recordSwitch(_ which: InputSwitch) {
        lastSwitch = which
        lastSwitchAt = Date()
    }
}
