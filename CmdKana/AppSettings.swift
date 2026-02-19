//
//  AppSettings.swift
//  CmdKana
//

import Foundation

@Observable
final class AppSettings {
    var showMenuBar: Bool {
        didSet { UserDefaults.standard.set(showMenuBar, forKey: "showMenuBar") }
    }

    init() {
        let stored = UserDefaults.standard.object(forKey: "showMenuBar")
        showMenuBar = (stored as? Bool) ?? true
    }
}
