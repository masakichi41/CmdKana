//
//  CmdKanaApp.swift
//  CmdKana
//

import SwiftUI

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
    private let accessibilityManager = AccessibilityManager()
    private var keyInterceptor: KeyInterceptor?
    private var statusItem: NSStatusItem?
    private var settingsWindow: NSWindow?

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
            let interceptor = KeyInterceptor()
            interceptor.start()
            self?.keyInterceptor = interceptor
        }
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem?.button?.image = NSImage(systemSymbolName: "command", accessibilityDescription: "CmdKana")

        let menu = NSMenu()
        menu.addItem(withTitle: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
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
        let hostingController = NSHostingController(rootView: settingsView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "CmdKana Settings"
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
