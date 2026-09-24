// Copyright 2026 Nick Fay
// SPDX-License-Identifier: Apache-2.0

import XCTest
@testable import SpeedyLauncher

final class ActionTypeTests: XCTestCase {

    // MARK: - Display Name Tests

    func testDisplayNameForApp() {
        XCTAssertEqual(ActionType.app.displayName, "Application")
    }

    func testDisplayNameForShortcut() {
        XCTAssertEqual(ActionType.shortcut.displayName, "Shortcut")
    }

    func testDisplayNameForFolder() {
        XCTAssertEqual(ActionType.folder.displayName, "Folder")
    }

    func testDisplayNameForCategory() {
        XCTAssertEqual(ActionType.category.displayName, "Category")
    }

    // MARK: - Default Icon Tests

    func testDefaultIconForApp() {
        XCTAssertEqual(ActionType.app.defaultIcon, "square.grid.2x2.fill")
    }

    func testDefaultIconForShortcut() {
        XCTAssertEqual(ActionType.shortcut.defaultIcon, "command.square.fill")
    }

    func testDefaultIconForFolder() {
        XCTAssertEqual(ActionType.folder.defaultIcon, "folder.fill")
    }

    func testDefaultIconForCategory() {
        XCTAssertEqual(ActionType.category.defaultIcon, "tray.full.fill")
    }

    // MARK: - Container Tests

    func testOnlyCategoryIsContainer() {
        XCTAssertFalse(ActionType.app.isContainer)
        XCTAssertFalse(ActionType.shortcut.isContainer)
        XCTAssertFalse(ActionType.folder.isContainer)
        XCTAssertTrue(ActionType.category.isContainer)
    }

    // MARK: - Codable Tests

    func testActionTypeCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for type in ActionType.allCases {
            let encoded = try encoder.encode(type)
            let decoded = try decoder.decode(ActionType.self, from: encoded)
            XCTAssertEqual(type, decoded)
        }
    }

    func testActionTypeRawValues() {
        XCTAssertEqual(ActionType.app.rawValue, "app")
        XCTAssertEqual(ActionType.shortcut.rawValue, "shortcut")
        XCTAssertEqual(ActionType.folder.rawValue, "folder")
        XCTAssertEqual(ActionType.category.rawValue, "category")
    }
}

final class ActionItemTests: XCTestCase {

    // MARK: - Initialization Tests

    func testDefaultInitialization() {
        let item = ActionItem(name: "Test", type: .app)

        XCTAssertEqual(item.name, "Test")
        XCTAssertEqual(item.type, .app)
        XCTAssertEqual(item.path, "")
        XCTAssertNil(item.icon)
        XCTAssertNil(item.keyboardShortcut)
        XCTAssertTrue(item.isEnabled)
        XCTAssertNil(item.children)
        XCTAssertTrue(item.isExpanded)
        XCTAssertNil(item.bookmarkData)
    }

    func testInitializationWithAllParameters() {
        let id = UUID()
        let shortcut = KeyboardShortcutConfig(key: "A", modifiers: [.command])
        let bookmarkData = Data([0x01, 0x02, 0x03])
        let item = ActionItem(
            id: id,
            name: "My App",
            type: .app,
            path: "/Applications/Test.app",
            icon: "star.fill",
            keyboardShortcut: shortcut,
            isEnabled: false,
            children: nil,
            isExpanded: false,
            bookmarkData: bookmarkData
        )

        XCTAssertEqual(item.id, id)
        XCTAssertEqual(item.name, "My App")
        XCTAssertEqual(item.type, .app)
        XCTAssertEqual(item.path, "/Applications/Test.app")
        XCTAssertEqual(item.icon, "star.fill")
        XCTAssertEqual(item.keyboardShortcut, shortcut)
        XCTAssertFalse(item.isEnabled)
        XCTAssertNil(item.children)
        XCTAssertFalse(item.isExpanded)
        XCTAssertEqual(item.bookmarkData, bookmarkData)
    }

    func testCategoryInitializationCreatesEmptyChildrenArray() {
        let category = ActionItem(name: "My Category", type: .category)

        XCTAssertNotNil(category.children)
        XCTAssertEqual(category.children?.count, 0)
    }

    func testCategoryInitializationWithChildren() {
        let child = ActionItem(name: "Child App", type: .app, path: "/Applications/App.app")
        let category = ActionItem(
            name: "My Category",
            type: .category,
            children: [child]
        )

        XCTAssertEqual(category.children?.count, 1)
        XCTAssertEqual(category.children?.first?.name, "Child App")
    }

    func testNonCategoryTypesDoNotHaveChildren() {
        let appItem = ActionItem(name: "App", type: .app, children: [ActionItem(name: "Child", type: .app)])
        let shortcutItem = ActionItem(name: "Shortcut", type: .shortcut, children: [ActionItem(name: "Child", type: .app)])
        let folderItem = ActionItem(name: "Folder", type: .folder, children: [ActionItem(name: "Child", type: .app)])

        XCTAssertNil(appItem.children)
        XCTAssertNil(shortcutItem.children)
        XCTAssertNil(folderItem.children)
    }

    // MARK: - Effective Icon Tests

    func testEffectiveIconReturnsCustomIconWhenSet() {
        let item = ActionItem(name: "Test", type: .app, icon: "custom.icon")
        XCTAssertEqual(item.effectiveIcon, "custom.icon")
    }

    func testEffectiveIconReturnsDefaultWhenIconIsNil() {
        let item = ActionItem(name: "Test", type: .app, icon: nil)
        XCTAssertEqual(item.effectiveIcon, ActionType.app.defaultIcon)
    }

    func testEffectiveIconReturnsDefaultWhenIconIsEmpty() {
        let item = ActionItem(name: "Test", type: .folder, icon: "")
        XCTAssertEqual(item.effectiveIcon, ActionType.folder.defaultIcon)
    }

    // MARK: - isCategory Tests

    func testIsCategoryForCategoryType() {
        let category = ActionItem(name: "Category", type: .category)
        XCTAssertTrue(category.isCategory)
    }

    func testIsCategoryForNonCategoryTypes() {
        XCTAssertFalse(ActionItem(name: "App", type: .app).isCategory)
        XCTAssertFalse(ActionItem(name: "Shortcut", type: .shortcut).isCategory)
        XCTAssertFalse(ActionItem(name: "Folder", type: .folder).isCategory)
    }

    // MARK: - Equatable Tests

    func testEquatableWithSameID() {
        let id = UUID()
        let item1 = ActionItem(id: id, name: "Item 1", type: .app)
        let item2 = ActionItem(id: id, name: "Item 1", type: .app)

        XCTAssertEqual(item1, item2)
    }

    func testEquatableWithDifferentID() {
        let item1 = ActionItem(name: "Item", type: .app)
        let item2 = ActionItem(name: "Item", type: .app)

        XCTAssertNotEqual(item1, item2)
    }

    // MARK: - Hashable Tests

    func testHashableInSet() {
        let item1 = ActionItem(name: "Item 1", type: .app)
        let item2 = ActionItem(name: "Item 2", type: .folder)
        let item3 = item1

        var set = Set<ActionItem>()
        set.insert(item1)
        set.insert(item2)
        set.insert(item3)

        XCTAssertEqual(set.count, 2)
    }

    // MARK: - Codable Tests

    func testCodableRoundTrip() throws {
        let shortcut = KeyboardShortcutConfig(key: "B", modifiers: [.command, .shift])
        let child = ActionItem(name: "Child", type: .app, path: "/Applications/Child.app")
        let item = ActionItem(
            name: "Category",
            type: .category,
            path: "",
            icon: "folder.badge.gear",
            keyboardShortcut: shortcut,
            isEnabled: true,
            children: [child],
            isExpanded: false
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(item)
        let decoded = try decoder.decode(ActionItem.self, from: data)

        XCTAssertEqual(decoded.name, item.name)
        XCTAssertEqual(decoded.type, item.type)
        XCTAssertEqual(decoded.icon, item.icon)
        XCTAssertEqual(decoded.keyboardShortcut, shortcut)
        XCTAssertEqual(decoded.isEnabled, item.isEnabled)
        XCTAssertEqual(decoded.children?.count, 1)
        XCTAssertEqual(decoded.isExpanded, false)
    }

    func testCodableRoundTripWithLaunchArguments() throws {
        let item = ActionItem(
            name: "Terminal",
            type: .app,
            path: "/Applications/Terminal.app",
            launchArguments: "--profile \"My Profile\" -x"
        )

        let data = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(ActionItem.self, from: data)

        XCTAssertEqual(decoded.launchArguments, "--profile \"My Profile\" -x")
    }

    func testDecodingWithoutLaunchArgumentsDefaultsToNil() throws {
        let item = ActionItem(name: "App", type: .app, path: "/Applications/App.app")
        let data = try JSONEncoder().encode(item)

        // Simulate legacy JSON saved before the field existed
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        json.removeValue(forKey: "launchArguments")
        let legacyData = try JSONSerialization.data(withJSONObject: json)

        let decoded = try JSONDecoder().decode(ActionItem.self, from: legacyData)
        XCTAssertNil(decoded.launchArguments)
    }
}

final class KeyboardShortcutConfigTests: XCTestCase {

    // MARK: - Display String Tests

    func testDisplayStringWithCommand() {
        let config = KeyboardShortcutConfig(key: "A", modifiers: [.command])
        XCTAssertEqual(config.displayString, "⌘ A")
    }

    func testDisplayStringWithOption() {
        let config = KeyboardShortcutConfig(key: "B", modifiers: [.option])
        XCTAssertEqual(config.displayString, "⌥ B")
    }

    func testDisplayStringWithControl() {
        let config = KeyboardShortcutConfig(key: "C", modifiers: [.control])
        XCTAssertEqual(config.displayString, "⌃ C")
    }

    func testDisplayStringWithShift() {
        let config = KeyboardShortcutConfig(key: "D", modifiers: [.shift])
        XCTAssertEqual(config.displayString, "⇧ D")
    }

    func testDisplayStringWithAllModifiers() {
        let config = KeyboardShortcutConfig(
            key: "E",
            modifiers: [.command, .option, .control, .shift]
        )
        // Order: control, option, shift, command
        XCTAssertEqual(config.displayString, "⌃ ⌥ ⇧ ⌘ E")
    }

    func testDisplayStringWithNoModifiers() {
        let config = KeyboardShortcutConfig(key: "F", modifiers: [])
        XCTAssertEqual(config.displayString, "F")
    }

    func testDisplayStringUppercasesKey() {
        let config = KeyboardShortcutConfig(key: "space", modifiers: [.command])
        XCTAssertEqual(config.displayString, "⌘ SPACE")
    }

    // MARK: - Equatable Tests

    func testEquatable() {
        let config1 = KeyboardShortcutConfig(key: "A", modifiers: [.command, .shift])
        let config2 = KeyboardShortcutConfig(key: "A", modifiers: [.command, .shift])
        let config3 = KeyboardShortcutConfig(key: "B", modifiers: [.command, .shift])

        XCTAssertEqual(config1, config2)
        XCTAssertNotEqual(config1, config3)
    }

    // MARK: - Codable Tests

    func testCodableRoundTrip() throws {
        let config = KeyboardShortcutConfig(
            key: "Space",
            modifiers: [.command, .shift]
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(config)
        let decoded = try decoder.decode(KeyboardShortcutConfig.self, from: data)

        XCTAssertEqual(decoded.key, config.key)
        XCTAssertEqual(decoded.modifiers, config.modifiers)
    }

    // MARK: - Modifier Tests

    func testModifierRawValues() {
        XCTAssertEqual(KeyboardShortcutConfig.Modifier.command.rawValue, "command")
        XCTAssertEqual(KeyboardShortcutConfig.Modifier.option.rawValue, "option")
        XCTAssertEqual(KeyboardShortcutConfig.Modifier.control.rawValue, "control")
        XCTAssertEqual(KeyboardShortcutConfig.Modifier.shift.rawValue, "shift")
    }
}
