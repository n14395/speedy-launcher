// Copyright 2026 Nick Fay
// SPDX-License-Identifier: Apache-2.0

import XCTest
@testable import SpeedyLauncher

final class AppSettingsTests: XCTestCase {

    // MARK: - Default Initialization Tests

    func testDefaultInitialization() {
        let settings = AppSettings()

        XCTAssertTrue(settings.items.isEmpty)
        XCTAssertNotNil(settings.globalHotkey)
        XCTAssertEqual(settings.globalHotkey?.key, "Space")
        XCTAssertEqual(settings.globalHotkey?.modifiers, [.command, .control])
        XCTAssertFalse(settings.launchAtLogin)
        XCTAssertTrue(settings.showMenuBarIcon)
        XCTAssertEqual(settings.menuBarIconName, "bookmark")
    }

    func testCustomInitialization() {
        let items = [ActionItem(name: "Test", type: .app)]
        let hotkey = KeyboardShortcutConfig(key: "A", modifiers: [.option])

        let settings = AppSettings(
            items: items,
            globalHotkey: hotkey,
            launchAtLogin: true,
            showMenuBarIcon: false,
            menuBarIconName: "star.fill"
        )

        XCTAssertEqual(settings.items.count, 1)
        XCTAssertEqual(settings.items.first?.name, "Test")
        XCTAssertEqual(settings.globalHotkey?.key, "A")
        XCTAssertEqual(settings.globalHotkey?.modifiers, [.option])
        XCTAssertTrue(settings.launchAtLogin)
        XCTAssertFalse(settings.showMenuBarIcon)
        XCTAssertEqual(settings.menuBarIconName, "star.fill")
    }

    func testInitializationWithNilHotkey() {
        let settings = AppSettings(
            items: [],
            globalHotkey: nil,
            launchAtLogin: false,
            showMenuBarIcon: true,
            menuBarIconName: "bookmark"
        )

        XCTAssertNil(settings.globalHotkey)
    }

    // MARK: - Default Static Property Tests

    func testDefaultStaticProperty() {
        let defaultSettings = AppSettings.default

        // Default settings have empty items (for first launch experience)
        XCTAssertTrue(defaultSettings.items.isEmpty)
        XCTAssertNotNil(defaultSettings.globalHotkey)
        XCTAssertFalse(defaultSettings.launchAtLogin)
        XCTAssertTrue(defaultSettings.showMenuBarIcon)
        XCTAssertEqual(defaultSettings.menuBarIconName, "bookmark")
        XCTAssertTrue(defaultSettings.enableKeyboardShortcuts)
    }

    // MARK: - Sample Items Tests

    func testSampleItemsContainsExpectedItems() {
        let sampleItems = AppSettings.sampleItems

        XCTAssertEqual(sampleItems.count, 5)

        // Verify Terminal
        let terminal = sampleItems[0]
        XCTAssertEqual(terminal.name, "Terminal")
        XCTAssertEqual(terminal.type, .app)
        XCTAssertEqual(terminal.path, "/System/Applications/Utilities/Terminal.app")

        // Verify Xcode
        let xcode = sampleItems[1]
        XCTAssertEqual(xcode.name, "Xcode")
        XCTAssertEqual(xcode.type, .app)
        XCTAssertEqual(xcode.path, "/Applications/Xcode.app")

        // Verify Development category
        let development = sampleItems[2]
        XCTAssertEqual(development.name, "Development")
        XCTAssertEqual(development.type, .category)
        XCTAssertEqual(development.icon, "hammer.fill")
        XCTAssertEqual(development.children?.count, 1)
        XCTAssertEqual(development.children?.first?.name, "VS Code")

        // Verify Downloads folder
        let downloads = sampleItems[3]
        XCTAssertEqual(downloads.name, "Downloads")
        XCTAssertEqual(downloads.type, .folder)
        XCTAssertEqual(downloads.path, "~/Downloads")

        // Verify Calculator
        let calculator = sampleItems[4]
        XCTAssertEqual(calculator.name, "Calculator")
        XCTAssertEqual(calculator.type, .app)
        XCTAssertEqual(calculator.path, "/System/Applications/Calculator.app")
    }

    func testSampleItemsCategoryHasChildren() {
        let sampleItems = AppSettings.sampleItems
        let developmentCategory = sampleItems.first { $0.type == .category }

        XCTAssertNotNil(developmentCategory)
        XCTAssertNotNil(developmentCategory?.children)
        XCTAssertEqual(developmentCategory?.children?.count, 1)

        let vsCode = developmentCategory?.children?.first
        XCTAssertEqual(vsCode?.name, "VS Code")
        XCTAssertEqual(vsCode?.type, .app)
        XCTAssertEqual(vsCode?.path, "/Applications/Visual Studio Code.app")
    }

    // MARK: - Codable Tests

    func testCodableRoundTrip() throws {
        let items = [
            ActionItem(name: "App1", type: .app, path: "/path/to/app"),
            ActionItem(name: "Shortcut", type: .shortcut, path: "My Shortcut")
        ]
        let hotkey = KeyboardShortcutConfig(key: "X", modifiers: [.command, .control])

        let settings = AppSettings(
            items: items,
            globalHotkey: hotkey,
            launchAtLogin: true,
            showMenuBarIcon: false,
            menuBarIconName: "gear",
            enableKeyboardShortcuts: true
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(settings)
        let decoded = try decoder.decode(AppSettings.self, from: data)

        XCTAssertEqual(decoded.items.count, 2)
        XCTAssertEqual(decoded.items[0].name, "App1")
        XCTAssertEqual(decoded.items[1].name, "Shortcut")
        XCTAssertEqual(decoded.globalHotkey?.key, "X")
        XCTAssertEqual(decoded.globalHotkey?.modifiers, [.command, .control])
        XCTAssertTrue(decoded.launchAtLogin)
        XCTAssertFalse(decoded.showMenuBarIcon)
        XCTAssertEqual(decoded.menuBarIconName, "gear")
        XCTAssertTrue(decoded.enableKeyboardShortcuts)
    }

    func testCodableWithNestedCategories() throws {
        let child = ActionItem(name: "Child", type: .app, path: "/path")
        let category = ActionItem(name: "Category", type: .category, children: [child])
        let settings = AppSettings(items: [category])

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(settings)
        let decoded = try decoder.decode(AppSettings.self, from: data)

        XCTAssertEqual(decoded.items.count, 1)
        XCTAssertEqual(decoded.items[0].name, "Category")
        XCTAssertEqual(decoded.items[0].children?.count, 1)
        XCTAssertEqual(decoded.items[0].children?[0].name, "Child")
    }

    func testCodableWithNilHotkey() throws {
        let settings = AppSettings(
            items: [],
            globalHotkey: nil,
            launchAtLogin: false,
            showMenuBarIcon: true,
            menuBarIconName: "bookmark"
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(settings)
        let decoded = try decoder.decode(AppSettings.self, from: data)

        XCTAssertNil(decoded.globalHotkey)
    }

    // MARK: - Shortcut Conflict Tests

    func testShortcutConflictNameFindsMenuHotkey() {
        let menuHotkey = KeyboardShortcutConfig(key: "Space", modifiers: [.command, .control])
        let settings = AppSettings(items: [], globalHotkey: menuHotkey)

        XCTAssertEqual(settings.shortcutConflictName(for: menuHotkey), "the menu shortcut")
    }

    func testShortcutConflictNameFindsTopLevelItem() {
        let shortcut = KeyboardShortcutConfig(key: "T", modifiers: [.command, .option])
        let item = ActionItem(name: "Terminal", type: .app, path: "/Applications/Terminal.app", keyboardShortcut: shortcut)
        let settings = AppSettings(items: [item], globalHotkey: nil)

        XCTAssertEqual(settings.shortcutConflictName(for: shortcut), "Terminal")
    }

    func testShortcutConflictNameFindsChildItem() {
        let shortcut = KeyboardShortcutConfig(key: "C", modifiers: [.command, .option])
        let category = ActionItem(
            name: "Group",
            type: .category,
            children: [
                ActionItem(name: "Child", type: .app, path: "/Applications/Child.app", keyboardShortcut: shortcut)
            ]
        )
        let settings = AppSettings(items: [category], globalHotkey: nil)

        XCTAssertEqual(settings.shortcutConflictName(for: shortcut), "Child")
    }

    func testShortcutConflictNameExcludesGivenItem() {
        let shortcut = KeyboardShortcutConfig(key: "T", modifiers: [.command, .option])
        let item = ActionItem(name: "Terminal", type: .app, path: "/Applications/Terminal.app", keyboardShortcut: shortcut)
        let settings = AppSettings(items: [item], globalHotkey: nil)

        XCTAssertNil(settings.shortcutConflictName(for: shortcut, excluding: item.id))
    }

    func testShortcutConflictNameReturnsNilWhenUnique() {
        let item = ActionItem(
            name: "Terminal",
            type: .app,
            path: "/Applications/Terminal.app",
            keyboardShortcut: KeyboardShortcutConfig(key: "T", modifiers: [.command, .option])
        )
        let settings = AppSettings(items: [item])

        let unique = KeyboardShortcutConfig(key: "U", modifiers: [.command, .option])
        XCTAssertNil(settings.shortcutConflictName(for: unique))
    }
}
