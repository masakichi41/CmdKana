//
//  SettingsView.swift
//  CmdKana
//

import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @State private var isLoginItemEnabled = (SMAppService.mainApp.status == .enabled)

    var body: some View {
        @Bindable var settings = settings
        Form {
            Section("General") {
                Toggle("Show menu bar icon", isOn: $settings.showMenuBar)

                Toggle("Start at Login", isOn: $isLoginItemEnabled)
                    .onChange(of: isLoginItemEnabled) { _, newValue in
                        toggleLoginItem(enabled: newValue)
                    }
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
