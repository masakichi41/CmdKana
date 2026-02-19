//
//  CmdKanaApp.swift
//  CmdKana
//

import SwiftUI
import ServiceManagement

@main
struct CmdKanaApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        MenuBarExtra("CmdKana", systemImage: "command") {
            MenuContent()
        }
    }
}

// MARK: - Menu Content

struct MenuContent: View {
    @State private var isLoginItemEnabled = (SMAppService.mainApp.status == .enabled)

    var body: some View {
        Toggle("Start at Login", isOn: $isLoginItemEnabled)
            .onChange(of: isLoginItemEnabled) { _, newValue in
                toggleLoginItem(enabled: newValue)
            }

        Divider()

        Button("Quit CmdKana") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
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

// MARK: - App Delegate

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let accessibilityManager = AccessibilityManager()
    private var keyInterceptor: KeyInterceptor?

    func applicationDidFinishLaunching(_ notification: Notification) {
        accessibilityManager.ensureAccessibility { [weak self] in
            let interceptor = KeyInterceptor()
            interceptor.start()
            self?.keyInterceptor = interceptor
        }
    }
}
