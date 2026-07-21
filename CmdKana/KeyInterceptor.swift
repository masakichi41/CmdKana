//
//  KeyInterceptor.swift
//  CmdKana
//

import Cocoa

// MARK: - Key Code Constants

private let kLeftCommand: CGKeyCode = 55
private let kRightCommand: CGKeyCode = 54
private let kEisuuKeyCode: CGKeyCode = 102
private let kKanaKeyCode: CGKeyCode = 104

/// modifierキーコードに対応するCGEventFlagsマスク。
/// flagsChangedイベントがキー押下か解放かを判定するために使用。
private let modifierMasks: [CGKeyCode: CGEventFlags] = [
    54: .maskCommand,   // Right Command
    55: .maskCommand,   // Left Command
]

// MARK: - KeyInterceptor

final class KeyInterceptor {

    /// 稼働状態と検出イベントを公開する診断モデル。
    private let status: AppStatus

    /// 単独押下を検出するための状態変数。
    /// Cmdキー押下時にkeyCodeを記録し、他のキーやマウス操作があればnilにリセット。
    private var pendingKeyCode: CGKeyCode? = nil

    /// CGEvent tapのCFMachPort参照（再有効化に使用）。
    private var eventTap: CFMachPort?

    private var globalMouseMonitor: Any?
    private var localMouseMonitor: Any?

    init(status: AppStatus) {
        self.status = status
    }

    func start() {
        setupMouseMonitors()
        setupEventTap()
    }

    // MARK: - Mouse Monitors

    /// マウスイベントでpendingKeyCodeをリセットする。
    /// CGEvent tapではなくNSEventを使用（ドラッグ関連バグの回避、cmd-eikanaと同じ方式）。
    private func setupMouseMonitors() {
        let mouseEventMask: NSEvent.EventTypeMask = [
            .leftMouseDown,
            .leftMouseUp,
            .rightMouseDown,
            .rightMouseUp,
            .otherMouseDown,
            .otherMouseUp,
            .scrollWheel
        ]

        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: mouseEventMask) { [weak self] _ in
            self?.pendingKeyCode = nil
        }

        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: mouseEventMask) { [weak self] event in
            self?.pendingKeyCode = nil
            return event
        }
    }

    // MARK: - CGEvent Tap Setup

    private func setupEventTap() {
        let eventMask: CGEventMask = (1 << CGEventType.flagsChanged.rawValue)
                                   | (1 << CGEventType.keyDown.rawValue)
                                   | (1 << CGEventType.keyUp.rawValue)

        let refcon = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        // @convention(c)コールバック。メインRunLoop上で実行されるため、
        // MainActor.assumeIsolatedで安全にMainActor隔離コードを呼び出せる。
        let callback: CGEventTapCallBack = { proxy, type, event, userInfo in
            guard let userInfo else {
                return Unmanaged.passUnretained(event)
            }
            let interceptor = Unmanaged<KeyInterceptor>.fromOpaque(userInfo).takeUnretainedValue()
            return MainActor.assumeIsolated {
                interceptor.handleEvent(proxy: proxy, type: type, event: event)
            }
        }

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: callback,
            userInfo: refcon
        ) else {
            print("CmdKana: Failed to create CGEvent tap.")
            status.interceptorRunning = false
            return
        }

        self.eventTap = tap

        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        status.interceptorRunning = true
    }

    // MARK: - Event Handling

    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)

        case .flagsChanged:
            return handleFlagsChanged(event: event)

        case .keyDown, .keyUp:
            pendingKeyCode = nil
            return Unmanaged.passUnretained(event)

        default:
            pendingKeyCode = nil
            return Unmanaged.passUnretained(event)
        }
    }

    // MARK: - Modifier Key Handling

    private func handleFlagsChanged(event: CGEvent) -> Unmanaged<CGEvent>? {
        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))

        guard let mask = modifierMasks[keyCode] else {
            // Cmd以外のmodifier（Shift, Option等）→ pendingをリセット
            pendingKeyCode = nil
            return Unmanaged.passUnretained(event)
        }

        let isKeyDown = event.flags.rawValue & mask.rawValue != 0

        if isKeyDown {
            pendingKeyCode = keyCode
        } else {
            if pendingKeyCode == keyCode {
                sendSyntheticKey(for: keyCode)
            }
            pendingKeyCode = nil
        }

        return Unmanaged.passUnretained(event)
    }

    // MARK: - Synthetic Key Event

    /// 英数(102)またはかな(104)の合成キーイベント（keyDown + keyUp）を送信する。
    private func sendSyntheticKey(for commandKeyCode: CGKeyCode) {
        let targetKeyCode: CGKeyCode
        switch commandKeyCode {
        case kLeftCommand:
            targetKeyCode = kEisuuKeyCode
        case kRightCommand:
            targetKeyCode = kKanaKeyCode
        default:
            return
        }

        let loc = CGEventTapLocation.cghidEventTap

        if let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: targetKeyCode, keyDown: true),
           let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: targetKeyCode, keyDown: false) {
            keyDown.flags = CGEventFlags()
            keyUp.flags = CGEventFlags()
            keyDown.post(tap: loc)
            keyUp.post(tap: loc)
            status.recordSwitch(commandKeyCode == kLeftCommand ? .eisuu : .kana)
        }
    }
}
