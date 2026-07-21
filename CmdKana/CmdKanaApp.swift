//
//  CmdKanaApp.swift
//  CmdKana
//

import SwiftUI
import Sparkle

@main
struct CmdKanaApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

// MARK: - App Delegate

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    let settings = AppSettings()
    let appStatus = AppStatus()
    private lazy var accessibilityManager = AccessibilityManager(status: appStatus)
    private var keyInterceptor: KeyInterceptor?
    private var statusItem: NSStatusItem?
    private var settingsWindow: NSWindow?

    private lazy var updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: self
    )
    private lazy var updaterViewModel = UpdaterViewModel(updater: updaterController.updater)

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleURLEvent(_:replyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        observeSettings()

        accessibilityManager.ensureAccessibility { [weak self] in
            guard let self else { return }
            let interceptor = KeyInterceptor(status: self.appStatus)
            interceptor.start()
            self.keyInterceptor = interceptor
        }
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem?.button?.image = NSImage(systemSymbolName: "command", accessibilityDescription: "CmdKana")

        let menu = NSMenu()
        menu.addItem(withTitle: "Settings...", action: #selector(openSettings), keyEquivalent: ",")

        let updatesItem = NSMenuItem(
            title: "Check for Updates…",
            action: #selector(SPUStandardUpdaterController.checkForUpdates(_:)),
            keyEquivalent: ""
        )
        updatesItem.target = updaterController
        menu.addItem(updatesItem)

        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit CmdKana", action: #selector(NSApplication.shared.terminate(_:)), keyEquivalent: "q")
        statusItem?.menu = menu

        statusItem?.isVisible = settings.showMenuBar
    }

    private func observeSettings() {
        withObservationTracking {
            _ = settings.showMenuBar
        } onChange: { [weak self] in
            DispatchQueue.main.async {
                self?.statusItem?.isVisible = self?.settings.showMenuBar ?? true
                self?.observeSettings()
            }
        }
    }

    // MARK: - Settings Window

    @objc private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)

        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            return
        }

        let settingsView = SettingsView()
            .environment(settings)
            .environment(appStatus)
            .environment(updaterViewModel)
        let hostingController = NSHostingController(rootView: settingsView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "CmdKana 設定"
        window.styleMask = [.titled, .closable]
        window.level = .floating
        window.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.center()
        window.makeKeyAndOrderFront(nil)

        settingsWindow = window
    }

    func windowWillClose(_ notification: Notification) {
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        openSettings()
        return false
    }

    // MARK: - URL Scheme

    @objc private func handleURLEvent(_ event: NSAppleEventDescriptor, replyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue,
              let url = URL(string: urlString),
              url.scheme == "cmdkana" else { return }

        if url.host == "settings" {
            openSettings()
        }
    }
}

// MARK: - Sparkle Gentle Reminders（LSUIElement 背景アプリ対応）

extension AppDelegate: SPUStandardUserDriverDelegate {
    var supportsGentleScheduledUpdateReminders: Bool { true }

    func standardUserDriverWillHandleShowingUpdate(
        _ handleShowingUpdate: Bool,
        forUpdate update: SUAppcastItem,
        state: SPUUserUpdateState
    ) {
        // 普段は Dock に出ない背景アプリ。更新ダイアログを見せる間だけ前面に出す。
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func standardUserDriverWillFinishUpdateSession() {
        // 更新セッション終了後は背景アプリに戻す。
        NSApp.setActivationPolicy(.accessory)
    }
}
