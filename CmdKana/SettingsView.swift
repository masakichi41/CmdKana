//
//  SettingsView.swift
//  CmdKana
//

import SwiftUI
import AppKit
import ServiceManagement

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(AppStatus.self) private var status
    @Environment(UpdaterViewModel.self) private var updater
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isLoginItemEnabled = (SMAppService.mainApp.status == .enabled)

    /// 押し込みアニメーション中のキー。
    @State private var pressedKey: InputSwitch? = nil
    /// ハイライト（発光）表示中のキー。押し込みより長く残す。
    @State private var glowingKey: InputSwitch? = nil
    @State private var keycapResetTask: Task<Void, Never>? = nil

    private var isHealthy: Bool {
        status.accessibilityTrusted && status.interceptorRunning
    }

    var body: some View {
        @Bindable var settings = settings
        @Bindable var updater = updater
        VStack(spacing: 0) {
            header

            Form {
                if !isHealthy {
                    attentionSection
                }

                Section("動作テスト") {
                    testRow
                }

                Section("一般") {
                    Toggle("メニューバーアイコンを表示", isOn: $settings.showMenuBar)
                    Toggle("ログイン時に起動", isOn: $isLoginItemEnabled)
                        .onChange(of: isLoginItemEnabled) { _, newValue in
                            toggleLoginItem(enabled: newValue)
                        }
                }

                Section("アップデート") {
                    Toggle("自動的に更新を確認", isOn: $updater.automaticallyChecksForUpdates)
                    Button("今すぐ更新を確認…") {
                        updater.checkForUpdates()
                    }
                    .disabled(!updater.canCheckForUpdates)
                }
            }
            .formStyle(.grouped)

            quitBar
        }
        .frame(width: 380)
        .fixedSize()
        .onChange(of: status.lastSwitchAt) {
            animateKeycap()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 2) {
                Text("CmdKana")
                    .font(.title2.bold())
                HStack(spacing: 6) {
                    Text("v\(versionString)")
                        .foregroundStyle(.secondary)
                    Circle()
                        .fill(isHealthy ? Color.green : Color.orange)
                        .frame(width: 7, height: 7)
                    Text(isHealthy ? "正常に動作中" : "対応が必要")
                        .foregroundStyle(.secondary)
                }
                .font(.callout)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 4)
        .animation(.easeOut(duration: 0.2), value: isHealthy)
    }

    // MARK: - Status（異常時のみ）

    private var attentionSection: some View {
        Section {
            if !status.accessibilityTrusted {
                LabeledContent {
                    Button("許可する…") { openAccessibilitySettings() }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Color.orange)
                        Text("アクセシビリティ権限が必要です")
                    }
                }
            } else if !status.interceptorRunning {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.orange)
                    Text("キー監視が停止しています。アプリを再起動してください。")
                }
            }
        }
    }

    // MARK: - 終了

    private var quitBar: some View {
        HStack {
            Spacer()
            quitButton
            Spacer()
        }
        .padding(.top, 2)
        .padding(.bottom, 16)
    }

    @ViewBuilder
    private var quitButton: some View {
        let button = Button("CmdKanaを終了") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)

        if #available(macOS 26.0, *) {
            button.buttonStyle(.glass)
        } else {
            button.buttonStyle(.bordered)
        }
    }

    // MARK: - 動作テスト

    private var testRow: some View {
        Group {
            if #available(macOS 26.0, *) {
                GlassEffectContainer(spacing: 16) { keycapRow }
            } else {
                keycapRow
            }
        }
        .padding(.vertical, 8)
    }

    private var keycapRow: some View {
        HStack(spacing: 16) {
            Spacer()
            keycap(key: "左 ⌘", output: "英数", which: .eisuu)
            keycap(key: "右 ⌘", output: "かな", which: .kana)
            Spacer()
        }
    }

    private func keycap(key: String, output: String, which: InputSwitch) -> some View {
        let isPressed = pressedKey == which
        let isGlowing = glowingKey == which
        let label = VStack(spacing: 3) {
            Text(key)
                .font(.system(.body, weight: .medium))
            Text(output)
                .font(.caption)
                .foregroundStyle(isGlowing ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.secondary))
        }
        .frame(width: 92, height: 60)

        return Group {
            if #available(macOS 26.0, *) {
                label.glassEffect(
                    isGlowing ? .regular.tint(Color.accentColor.opacity(0.35)) : .regular,
                    in: .rect(cornerRadius: 14)
                )
            } else {
                label
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(nsColor: .controlBackgroundColor))
                            .shadow(
                                color: .black.opacity(isPressed ? 0.06 : 0.18),
                                radius: isPressed ? 1 : 2.5,
                                y: isPressed ? 0.5 : 2
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(
                                isGlowing ? Color.accentColor : Color.primary.opacity(0.08),
                                lineWidth: isGlowing ? 1.5 : 1
                            )
                    )
            }
        }
        .scaleEffect(isPressed ? 0.94 : 1)
        .animation(.easeOut(duration: 0.25), value: isGlowing)
    }

    /// 左右⌘の単独押しを検知したら、該当キーキャップを押し込み→スプリング復帰させ、
    /// ハイライトを少し残してからフェードアウトする。
    /// 同じキーの連打でも毎回発火するよう `lastSwitchAt`（時刻）の変化で呼ばれる。
    private func animateKeycap() {
        guard let which = status.lastSwitch else { return }
        keycapResetTask?.cancel()

        if reduceMotion {
            // バウンス・スケールは使わずハイライトのクロスフェードのみ
            glowingKey = which
        } else {
            withAnimation(.spring(duration: 0.12)) { pressedKey = which }
            glowingKey = which
        }

        keycapResetTask = Task {
            try? await Task.sleep(for: .milliseconds(120))
            guard !Task.isCancelled else { return }
            withAnimation(.spring(duration: 0.35, bounce: reduceMotion ? 0 : 0.25)) {
                pressedKey = nil
            }
            try? await Task.sleep(for: .milliseconds(450))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.3)) { glowingKey = nil }
        }
    }

    // MARK: - Helpers

    private var versionString: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "\(short) (\(build))"
    }

    private func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    private func toggleLoginItem(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("CmdKana: Failed to \(enabled ? "register" : "unregister") login item: \(error)")
            isLoginItemEnabled = !enabled
        }
    }
}
