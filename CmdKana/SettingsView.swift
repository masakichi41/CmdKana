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
    @State private var isLoginItemEnabled = (SMAppService.mainApp.status == .enabled)

    var body: some View {
        @Bindable var settings = settings
        @Bindable var updater = updater
        Form {
            Section("General") {
                Toggle("Show menu bar icon", isOn: $settings.showMenuBar)

                Toggle("Start at Login", isOn: $isLoginItemEnabled)
                    .onChange(of: isLoginItemEnabled) { _, newValue in
                        toggleLoginItem(enabled: newValue)
                    }
            }

            Section("Status") {
                accessibilityRow
                LabeledContent("キー監視") {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(status.interceptorRunning ? Color.green : Color.secondary)
                            .frame(width: 8, height: 8)
                        Text(status.interceptorRunning ? "稼働中" : "停止中")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Test") {
                Text("左⌘で英数、右⌘でかなに切り替わります。ここで押して動作を確認できます。")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                HStack(spacing: 10) {
                    testChip(title: "左⌘ → 英数", active: status.lastSwitch == .eisuu)
                    testChip(title: "右⌘ → かな", active: status.lastSwitch == .kana)
                    Spacer()
                }
                .animation(.easeOut(duration: 0.15), value: status.lastSwitch)
            }

            Section("About") {
                LabeledContent("バージョン", value: versionString)

                Toggle("自動的に更新を確認", isOn: $updater.automaticallyChecksForUpdates)

                Button("今すぐ更新を確認…") {
                    updater.checkForUpdates()
                }
                .disabled(!updater.canCheckForUpdates)
            }

            if !settings.showMenuBar {
                Section {
                    Text("メニューバーアイコンが非表示のとき、Finder等からCmdKanaを開くとこの設定画面が表示されます。")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 380)
        .fixedSize()
    }

    // MARK: - Subviews

    private var accessibilityRow: some View {
        LabeledContent {
            if status.accessibilityTrusted {
                Text("許可済み").foregroundStyle(.secondary)
            } else {
                Button("システム設定を開く…") { openAccessibilitySettings() }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: status.accessibilityTrusted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(status.accessibilityTrusted ? Color.green : Color.orange)
                Text("アクセシビリティ権限")
            }
        }
    }

    private func testChip(title: String, active: Bool) -> some View {
        Text(title)
            .font(.callout)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                active ? Color.accentColor.opacity(0.25) : Color.secondary.opacity(0.12),
                in: Capsule()
            )
            .overlay(
                Capsule().strokeBorder(active ? Color.accentColor : Color.clear, lineWidth: 1)
            )
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
