//
//  AccessibilityManager.swift
//  CmdKana
//

import Cocoa

final class AccessibilityManager {

    private let status: AppStatus
    private var pollTimer: Timer?
    private var didComplete = false
    private var onTrusted: (() -> Void)?

    init(status: AppStatus) {
        self.status = status
    }

    /// Accessibility権限を確認し、許可済みならcompletionを一度だけ呼び出す。
    /// 未許可の場合はシステムプロンプトを表示する。
    /// いずれの場合も権限状態をポーリングで監視し続け、`AppStatus` に反映する
    /// （許可後に剥奪されたケースも設定画面に表示できるようにするため）。
    func ensureAccessibility(completion: @escaping () -> Void) {
        onTrusted = completion

        let options = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
        ] as CFDictionary

        let trusted = AXIsProcessTrustedWithOptions(options)
        status.accessibilityTrusted = trusted
        if trusted {
            fireCompletionIfNeeded()
        }

        startMonitoring()
    }

    private func startMonitoring() {
        guard pollTimer == nil else { return }
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            let trusted = AXIsProcessTrusted()
            self.status.accessibilityTrusted = trusted
            if trusted {
                self.fireCompletionIfNeeded()
            }
        }
    }

    private func fireCompletionIfNeeded() {
        guard !didComplete else { return }
        didComplete = true
        onTrusted?()
    }
}
