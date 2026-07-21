//
//  UpdaterViewModel.swift
//  CmdKana
//

import Foundation
import Sparkle

/// SwiftUI から Sparkle の updater を扱うための薄いラッパー。
/// `canCheckForUpdates` を KVO で監視し、`@Observable` 経由で設定画面に反映する。
@Observable
final class UpdaterViewModel {
    private let updater: SPUUpdater
    private var canCheckObservation: NSKeyValueObservation?

    /// 更新チェックが実行可能か（チェック実行中は false）。ボタンの有効/無効に使う。
    var canCheckForUpdates = false

    /// 自動更新チェックの有効/無効。変更は即座に updater に反映する。
    var automaticallyChecksForUpdates: Bool {
        didSet { updater.automaticallyChecksForUpdates = automaticallyChecksForUpdates }
    }

    init(updater: SPUUpdater) {
        self.updater = updater
        self.automaticallyChecksForUpdates = updater.automaticallyChecksForUpdates
        self.canCheckForUpdates = updater.canCheckForUpdates
        self.canCheckObservation = updater.observe(\.canCheckForUpdates, options: [.new]) { [weak self] updater, _ in
            self?.canCheckForUpdates = updater.canCheckForUpdates
        }
    }

    /// ユーザー操作による更新チェックを開始する（結果ダイアログを表示）。
    func checkForUpdates() {
        updater.checkForUpdates()
    }
}
