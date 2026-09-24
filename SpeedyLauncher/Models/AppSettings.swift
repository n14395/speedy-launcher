// Copyright 2026 Nick Fay
// SPDX-License-Identifier: Apache-2.0

import Foundation

struct AppSettings: Codable {
    var items: [ActionItem]
    var globalHotkey: KeyboardShortcutConfig?
    var launchAtLogin: Bool
    var showMenuBarIcon: Bool
    var menuBarIconName: String
    var enableKeyboardShortcuts: Bool

    init(
        items: [ActionItem] = [],
        globalHotkey: KeyboardShortcutConfig? = KeyboardShortcutConfig(
            key: "Space",
            modifiers: [.command, .control]
        ),
        launchAtLogin: Bool = false,
        showMenuBarIcon: Bool = true,
        menuBarIconName: String = "bookmark",
        enableKeyboardShortcuts: Bool = true
    ) {
        self.items = items
        self.globalHotkey = globalHotkey
        self.launchAtLogin = launchAtLogin
        self.showMenuBarIcon = showMenuBarIcon
        self.menuBarIconName = menuBarIconName
        self.enableKeyboardShortcuts = enableKeyboardShortcuts
    }

    static var `default`: AppSettings {
        AppSettings()
    }

    /// Returns the name of whatever already uses `config` — "the menu shortcut" or
    /// another item's name — or nil if the shortcut is unused. Pass `excluding` to
    /// ignore the item currently being edited.
    func shortcutConflictName(for config: KeyboardShortcutConfig, excluding itemID: UUID? = nil) -> String? {
        if globalHotkey == config {
            return "the menu shortcut"
        }

        let flat = items.flatMap { [$0] + ($0.children ?? []) }
        return flat.first { $0.id != itemID && $0.keyboardShortcut == config }?.name
    }

    static var sampleItems: [ActionItem] {
        [
            ActionItem(name: "Terminal", type: .app, path: "/System/Applications/Utilities/Terminal.app"),
            ActionItem(name: "Xcode", type: .app, path: "/Applications/Xcode.app"),
            ActionItem(
                name: "Development",
                type: .category,
                icon: "hammer.fill",
                children: [
                    ActionItem(name: "VS Code", type: .app, path: "/Applications/Visual Studio Code.app")
                ]
            ),
            ActionItem(name: "Downloads", type: .folder, path: "~/Downloads"),
            ActionItem(name: "Calculator", type: .app, path: "/System/Applications/Calculator.app")
        ]
    }
}
