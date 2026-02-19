//
//  AccessibilityManager.swift
//  CmdKana
//

import Cocoa

final class AccessibilityManager {

    private var pollTimer: Timer?

    /// Accessibility権限を確認し、許可済みならcompletionを即時呼び出す。
    /// 未許可の場合はシステムプロンプトを表示し、許可されるまでポーリングする。
    func ensureAccessibility(completion: @escaping () -> Void) {
        let options = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
        ] as CFDictionary

        if AXIsProcessTrustedWithOptions(options) {
            completion()
            return
        }

        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            if AXIsProcessTrusted() {
                timer.invalidate()
                self?.pollTimer = nil
                completion()
            }
        }
    }
}
