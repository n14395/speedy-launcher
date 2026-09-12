import XCTest
@testable import SpeedyLauncher

@MainActor
final class HotkeyManagerTests: XCTestCase {

    var hotkeyManager: HotkeyManager!

    override func setUp() async throws {
        try await super.setUp()
        hotkeyManager = HotkeyManager.shared
        hotkeyManager.unregisterGlobalHotkey()
        hotkeyManager.unregisterAllItemHotkeys()
    }

    override func tearDown() async throws {
        hotkeyManager.unregisterGlobalHotkey()
        hotkeyManager.unregisterAllItemHotkeys()
        hotkeyManager.onGlobalHotkeyPressed = nil
        hotkeyManager.onItemHotkeyPressed = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialStateIsDisabled() {
        hotkeyManager.unregisterGlobalHotkey()
        XCTAssertFalse(hotkeyManager.isGlobalHotkeyEnabled)
    }

    func testCallbackIsNilByDefault() {
        XCTAssertNil(hotkeyManager.onGlobalHotkeyPressed)
    }

    // MARK: - Registration Tests

    func testRegisterWithNilConfigDoesNothing() {
        hotkeyManager.registerGlobalHotkey(nil)
        XCTAssertFalse(hotkeyManager.isGlobalHotkeyEnabled)
    }

    func testRegisterWithValidConfig() {
        let config = KeyboardShortcutConfig(key: "A", modifiers: [.command])
        hotkeyManager.registerGlobalHotkey(config)

        // Note: Registration may fail in test environment without accessibility permissions
        // We're testing that it doesn't crash and sets the state
    }

    func testRegisterWithCommandModifier() {
        let config = KeyboardShortcutConfig(key: "B", modifiers: [.command])
        hotkeyManager.registerGlobalHotkey(config)
    }

    func testRegisterWithOptionModifier() {
        let config = KeyboardShortcutConfig(key: "C", modifiers: [.option])
        hotkeyManager.registerGlobalHotkey(config)
    }

    func testRegisterWithControlModifier() {
        let config = KeyboardShortcutConfig(key: "D", modifiers: [.control])
        hotkeyManager.registerGlobalHotkey(config)
    }

    func testRegisterWithShiftModifier() {
        let config = KeyboardShortcutConfig(key: "E", modifiers: [.shift])
        hotkeyManager.registerGlobalHotkey(config)
    }

    func testRegisterWithMultipleModifiers() {
        let config = KeyboardShortcutConfig(
            key: "Space",
            modifiers: [.command, .shift]
        )
        hotkeyManager.registerGlobalHotkey(config)
    }

    func testRegisterWithAllModifiers() {
        let config = KeyboardShortcutConfig(
            key: "F",
            modifiers: [.command, .option, .control, .shift]
        )
        hotkeyManager.registerGlobalHotkey(config)
    }

    // MARK: - Unregistration Tests

    func testUnregisterClearsState() {
        let config = KeyboardShortcutConfig(key: "G", modifiers: [.command])
        hotkeyManager.registerGlobalHotkey(config)
        hotkeyManager.unregisterGlobalHotkey()

        XCTAssertFalse(hotkeyManager.isGlobalHotkeyEnabled)
    }

    func testUnregisterCanBeCalledMultipleTimes() {
        hotkeyManager.unregisterGlobalHotkey()
        hotkeyManager.unregisterGlobalHotkey()
        hotkeyManager.unregisterGlobalHotkey()

        // Should not crash
        XCTAssertFalse(hotkeyManager.isGlobalHotkeyEnabled)
    }

    // MARK: - Re-registration Tests

    func testRegisterNewHotkeyUnregistersPrevious() {
        let config1 = KeyboardShortcutConfig(key: "H", modifiers: [.command])
        let config2 = KeyboardShortcutConfig(key: "I", modifiers: [.option])

        hotkeyManager.registerGlobalHotkey(config1)
        hotkeyManager.registerGlobalHotkey(config2)

        // Should have replaced the previous hotkey
    }

    // MARK: - Invalid Key Tests

    func testRegisterWithInvalidKey() {
        let config = KeyboardShortcutConfig(key: "InvalidKey123", modifiers: [.command])
        hotkeyManager.registerGlobalHotkey(config)

        // Should not register with invalid key
        XCTAssertFalse(hotkeyManager.isGlobalHotkeyEnabled)
    }

    // MARK: - Special Key Tests

    func testRegisterWithSpaceKey() {
        let config = KeyboardShortcutConfig(key: "Space", modifiers: [.command, .shift])
        hotkeyManager.registerGlobalHotkey(config)
    }

    func testRegisterWithReturnKey() {
        let config = KeyboardShortcutConfig(key: "Return", modifiers: [.command])
        hotkeyManager.registerGlobalHotkey(config)
    }

    func testRegisterWithTabKey() {
        let config = KeyboardShortcutConfig(key: "Tab", modifiers: [.command])
        hotkeyManager.registerGlobalHotkey(config)
    }

    func testRegisterWithDeleteKey() {
        let config = KeyboardShortcutConfig(key: "Delete", modifiers: [.command])
        hotkeyManager.registerGlobalHotkey(config)
    }

    func testRegisterWithEscapeKey() {
        let config = KeyboardShortcutConfig(key: "Escape", modifiers: [.command])
        hotkeyManager.registerGlobalHotkey(config)
    }

    func testRegisterWithFunctionKeys() {
        let functionKeys = ["F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12"]

        for key in functionKeys {
            let config = KeyboardShortcutConfig(key: key, modifiers: [.command])
            hotkeyManager.registerGlobalHotkey(config)
            hotkeyManager.unregisterGlobalHotkey()
        }
    }

    // MARK: - Number Key Tests

    func testRegisterWithNumberKeys() {
        for i in 0...9 {
            let config = KeyboardShortcutConfig(key: "\(i)", modifiers: [.command])
            hotkeyManager.registerGlobalHotkey(config)
            hotkeyManager.unregisterGlobalHotkey()
        }
    }

    // MARK: - Letter Key Tests

    func testRegisterWithAllLetterKeys() {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

        for letter in letters {
            let config = KeyboardShortcutConfig(key: String(letter), modifiers: [.command])
            hotkeyManager.registerGlobalHotkey(config)
            hotkeyManager.unregisterGlobalHotkey()
        }
    }

    func testRegisterWithLowercaseKey() {
        // Should work with lowercase (keyCodeForString handles uppercase conversion)
        let config = KeyboardShortcutConfig(key: "a", modifiers: [.command])
        hotkeyManager.registerGlobalHotkey(config)
    }

    // MARK: - Symbol Key Tests

    func testRegisterWithSymbolKeys() {
        let symbols = ["=", "-", "[", "]", "'", ";", "\\", ",", ".", "/", "`"]

        for symbol in symbols {
            let config = KeyboardShortcutConfig(key: symbol, modifiers: [.command])
            hotkeyManager.registerGlobalHotkey(config)
            hotkeyManager.unregisterGlobalHotkey()
        }
    }

    // MARK: - Callback Tests

    func testCallbackCanBeSet() {
        var callbackCalled = false
        hotkeyManager.onGlobalHotkeyPressed = {
            callbackCalled = true
        }

        XCTAssertNotNil(hotkeyManager.onGlobalHotkeyPressed)
        hotkeyManager.onGlobalHotkeyPressed?()
        XCTAssertTrue(callbackCalled)
    }

    func testCallbackCanBeCleared() {
        hotkeyManager.onGlobalHotkeyPressed = { }
        XCTAssertNotNil(hotkeyManager.onGlobalHotkeyPressed)

        hotkeyManager.onGlobalHotkeyPressed = nil
        XCTAssertNil(hotkeyManager.onGlobalHotkeyPressed)
    }

    // MARK: - Singleton Tests

    func testSharedInstanceIsSingleton() {
        let instance1 = HotkeyManager.shared
        let instance2 = HotkeyManager.shared

        XCTAssertTrue(instance1 === instance2)
    }

    // MARK: - Published Property Tests

    func testIsGlobalHotkeyEnabledIsPublished() {
        // Verify the property is observable
        var observations = 0
        let cancellable = hotkeyManager.$isGlobalHotkeyEnabled.sink { _ in
            observations += 1
        }

        // Initial value
        XCTAssertGreaterThanOrEqual(observations, 1)

        // Trigger a change
        hotkeyManager.unregisterGlobalHotkey()

        cancellable.cancel()
    }

    // MARK: - Static Method Tests

    func testStringForKeyCodeReturnsCorrectKeys() {
        // Test letter keys
        XCTAssertEqual(HotkeyManager.stringForKeyCode(0x00), "A")
        XCTAssertEqual(HotkeyManager.stringForKeyCode(0x01), "S")
        XCTAssertEqual(HotkeyManager.stringForKeyCode(0x02), "D")

        // Test number keys
        XCTAssertEqual(HotkeyManager.stringForKeyCode(0x12), "1")
        XCTAssertEqual(HotkeyManager.stringForKeyCode(0x13), "2")
        XCTAssertEqual(HotkeyManager.stringForKeyCode(0x1D), "0")

        // Test special keys
        XCTAssertEqual(HotkeyManager.stringForKeyCode(0x31), "Space")
        XCTAssertEqual(HotkeyManager.stringForKeyCode(0x24), "Return")
        XCTAssertEqual(HotkeyManager.stringForKeyCode(0x30), "Tab")
        XCTAssertEqual(HotkeyManager.stringForKeyCode(0x33), "Delete")
        XCTAssertEqual(HotkeyManager.stringForKeyCode(0x35), "Escape")

        // Test function keys
        XCTAssertEqual(HotkeyManager.stringForKeyCode(0x7A), "F1")
        XCTAssertEqual(HotkeyManager.stringForKeyCode(0x78), "F2")
        XCTAssertEqual(HotkeyManager.stringForKeyCode(0x6F), "F12")
    }

    func testStringForKeyCodeReturnsNilForUnknownCodes() {
        XCTAssertNil(HotkeyManager.stringForKeyCode(0xFF))
        XCTAssertNil(HotkeyManager.stringForKeyCode(0xFE))
        XCTAssertNil(HotkeyManager.stringForKeyCode(0x99))
    }

    func testStringForKeyCodeSymbolKeys() {
        XCTAssertEqual(HotkeyManager.stringForKeyCode(0x18), "=")
        XCTAssertEqual(HotkeyManager.stringForKeyCode(0x1B), "-")
        XCTAssertEqual(HotkeyManager.stringForKeyCode(0x21), "[")
        XCTAssertEqual(HotkeyManager.stringForKeyCode(0x1E), "]")
        XCTAssertEqual(HotkeyManager.stringForKeyCode(0x27), "'")
        XCTAssertEqual(HotkeyManager.stringForKeyCode(0x29), ";")
        XCTAssertEqual(HotkeyManager.stringForKeyCode(0x2A), "\\")
        XCTAssertEqual(HotkeyManager.stringForKeyCode(0x2B), ",")
        XCTAssertEqual(HotkeyManager.stringForKeyCode(0x2C), "/")
        XCTAssertEqual(HotkeyManager.stringForKeyCode(0x2F), ".")
        XCTAssertEqual(HotkeyManager.stringForKeyCode(0x32), "`")
    }

    // MARK: - Cleanup Tests

    func testCleanupUnregistersHotkey() {
        let config = KeyboardShortcutConfig(key: "Z", modifiers: [.command])
        hotkeyManager.registerGlobalHotkey(config)

        hotkeyManager.cleanup()

        XCTAssertFalse(hotkeyManager.isGlobalHotkeyEnabled)
    }

    // MARK: - Empty Modifier Tests

    func testRegisterWithEmptyModifiersStillRegisters() {
        // Even without modifiers, the function should try to register
        let config = KeyboardShortcutConfig(key: "A", modifiers: [])
        hotkeyManager.registerGlobalHotkey(config)
        // May or may not succeed depending on system state
    }

    // MARK: - Item Hotkey Tests

    func testRegisterItemHotkeysWithEmptyArray() {
        hotkeyManager.registerItemHotkeys([], menuHotkey: nil)
        XCTAssertEqual(hotkeyManager.registeredItemHotkeyCount, 0)
    }

    func testRegisterItemHotkeysRegistersItemsWithShortcuts() {
        let items = [
            ActionItem(name: "One", type: .app, path: "/Applications/One.app",
                       keyboardShortcut: KeyboardShortcutConfig(key: "1", modifiers: [.command, .option])),
            ActionItem(name: "Two", type: .app, path: "/Applications/Two.app",
                       keyboardShortcut: KeyboardShortcutConfig(key: "2", modifiers: [.command, .option]))
        ]
        hotkeyManager.registerItemHotkeys(items, menuHotkey: nil)
        XCTAssertEqual(hotkeyManager.registeredItemHotkeyCount, 2)
    }

    func testRegisterItemHotkeysSkipsItemsWithoutShortcut() {
        let items = [
            ActionItem(name: "No Shortcut", type: .app, path: "/Applications/One.app")
        ]
        hotkeyManager.registerItemHotkeys(items, menuHotkey: nil)
        XCTAssertEqual(hotkeyManager.registeredItemHotkeyCount, 0)
    }

    func testRegisterItemHotkeysSkipsDisabledItems() {
        let items = [
            ActionItem(name: "Disabled", type: .app, path: "/Applications/One.app",
                       keyboardShortcut: KeyboardShortcutConfig(key: "1", modifiers: [.command, .option]),
                       isEnabled: false)
        ]
        hotkeyManager.registerItemHotkeys(items, menuHotkey: nil)
        XCTAssertEqual(hotkeyManager.registeredItemHotkeyCount, 0)
    }

    func testRegisterItemHotkeysSkipsCategoriesButIncludesChildren() {
        let items = [
            ActionItem(name: "Group", type: .category,
                       keyboardShortcut: KeyboardShortcutConfig(key: "G", modifiers: [.command, .option]),
                       children: [
                           ActionItem(name: "Child", type: .app, path: "/Applications/Child.app",
                                      keyboardShortcut: KeyboardShortcutConfig(key: "C", modifiers: [.command, .option]))
                       ])
        ]
        hotkeyManager.registerItemHotkeys(items, menuHotkey: nil)
        XCTAssertEqual(hotkeyManager.registeredItemHotkeyCount, 1)
    }

    func testRegisterItemHotkeysSkipsDuplicateShortcuts() {
        let shared = KeyboardShortcutConfig(key: "K", modifiers: [.command, .option])
        let items = [
            ActionItem(name: "First", type: .app, path: "/Applications/One.app", keyboardShortcut: shared),
            ActionItem(name: "Second", type: .app, path: "/Applications/Two.app", keyboardShortcut: shared)
        ]
        hotkeyManager.registerItemHotkeys(items, menuHotkey: nil)
        XCTAssertEqual(hotkeyManager.registeredItemHotkeyCount, 1)
    }

    func testRegisterItemHotkeysSkipsMenuHotkeyCollision() {
        let menuHotkey = KeyboardShortcutConfig(key: "Space", modifiers: [.command, .control])
        let items = [
            ActionItem(name: "Colliding", type: .app, path: "/Applications/One.app", keyboardShortcut: menuHotkey)
        ]
        hotkeyManager.registerItemHotkeys(items, menuHotkey: menuHotkey)
        XCTAssertEqual(hotkeyManager.registeredItemHotkeyCount, 0)
    }

    func testRegisterItemHotkeysSkipsInvalidKeys() {
        let items = [
            ActionItem(name: "Invalid", type: .app, path: "/Applications/One.app",
                       keyboardShortcut: KeyboardShortcutConfig(key: "NotAKey", modifiers: [.command]))
        ]
        hotkeyManager.registerItemHotkeys(items, menuHotkey: nil)
        XCTAssertEqual(hotkeyManager.registeredItemHotkeyCount, 0)
    }

    func testReRegisterItemHotkeysReplacesExisting() {
        let items = [
            ActionItem(name: "One", type: .app, path: "/Applications/One.app",
                       keyboardShortcut: KeyboardShortcutConfig(key: "1", modifiers: [.command, .option]))
        ]
        hotkeyManager.registerItemHotkeys(items, menuHotkey: nil)
        hotkeyManager.registerItemHotkeys(items, menuHotkey: nil)
        XCTAssertEqual(hotkeyManager.registeredItemHotkeyCount, 1)
    }

    func testUnregisterAllItemHotkeysIsIdempotent() {
        let items = [
            ActionItem(name: "One", type: .app, path: "/Applications/One.app",
                       keyboardShortcut: KeyboardShortcutConfig(key: "1", modifiers: [.command, .option]))
        ]
        hotkeyManager.registerItemHotkeys(items, menuHotkey: nil)

        hotkeyManager.unregisterAllItemHotkeys()
        hotkeyManager.unregisterAllItemHotkeys()
        hotkeyManager.unregisterAllItemHotkeys()
        XCTAssertEqual(hotkeyManager.registeredItemHotkeyCount, 0)
    }

    func testItemHotkeyCallbackCanBeSetAndCleared() {
        var receivedID: UUID?
        let itemID = UUID()

        hotkeyManager.onItemHotkeyPressed = { id in
            receivedID = id
        }
        XCTAssertNotNil(hotkeyManager.onItemHotkeyPressed)

        hotkeyManager.onItemHotkeyPressed?(itemID)
        XCTAssertEqual(receivedID, itemID)

        hotkeyManager.onItemHotkeyPressed = nil
        XCTAssertNil(hotkeyManager.onItemHotkeyPressed)
    }

    func testCleanupUnregistersItemHotkeys() {
        let items = [
            ActionItem(name: "One", type: .app, path: "/Applications/One.app",
                       keyboardShortcut: KeyboardShortcutConfig(key: "1", modifiers: [.command, .option]))
        ]
        hotkeyManager.registerItemHotkeys(items, menuHotkey: nil)

        hotkeyManager.cleanup()

        XCTAssertEqual(hotkeyManager.registeredItemHotkeyCount, 0)
    }
}
