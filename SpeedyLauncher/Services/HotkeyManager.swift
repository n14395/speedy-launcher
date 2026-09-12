import Foundation
import Carbon
import AppKit

@MainActor
class HotkeyManager: ObservableObject {
    static let shared = HotkeyManager()

    @Published var isGlobalHotkeyEnabled: Bool = false

    private var globalHotkeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?

    // Per-item hotkeys. Carbon id 1 is reserved for the menu hotkey;
    // item ids start at 2 and are never reused within a process lifetime.
    private var itemHotkeyRefs: [UInt32: EventHotKeyRef] = [:]
    private var idToItemUUID: [UInt32: UUID] = [:]
    private var itemUUIDToID: [UUID: UInt32] = [:]
    private var nextHotkeyID: UInt32 = 2

    var onGlobalHotkeyPressed: (() -> Void)?
    var onItemHotkeyPressed: ((UUID) -> Void)?

    var registeredItemHotkeyCount: Int { itemHotkeyRefs.count }

    private static let hotkeySignature = OSType(0x53504C43) // "SPLC" - legacy SpeedLauncher signature, kept stable across the SpeedyLauncher rename
    private static let menuHotkeyID: UInt32 = 1

    private init() {}

    func registerGlobalHotkey(_ config: KeyboardShortcutConfig?) {
        unregisterGlobalHotkey()

        guard let config = config else { return }

        let keyCode = keyCodeForString(config.key)
        guard keyCode != UInt32.max else {
            print("Invalid key: \(config.key)")
            return
        }

        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = Self.hotkeySignature
        hotKeyID.id = Self.menuHotkeyID

        ensureEventHandler()

        let status = RegisterEventHotKey(
            keyCode,
            carbonModifiers(for: config),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &globalHotkeyRef
        )

        isGlobalHotkeyEnabled = status == noErr
        if status != noErr {
            print("Failed to register hotkey: \(status)")
        }
    }

    func unregisterGlobalHotkey() {
        if let hotKeyRef = globalHotkeyRef {
            UnregisterEventHotKey(hotKeyRef)
            globalHotkeyRef = nil
        }

        isGlobalHotkeyEnabled = false
    }

    /// Registers a global hotkey for every enabled, non-category item (including one
    /// level of category children) that has a shortcut assigned. Previously registered
    /// item hotkeys are replaced. Duplicate shortcuts are skipped (first wins), as is
    /// any shortcut matching `menuHotkey` — Carbon would otherwise fire both.
    func registerItemHotkeys(_ items: [ActionItem], menuHotkey: KeyboardShortcutConfig?) {
        unregisterAllItemHotkeys()
        ensureEventHandler()

        var seen = Set<KeyboardShortcutConfig>()
        if let menuHotkey = menuHotkey {
            seen.insert(menuHotkey)
        }

        let flat = items.flatMap { [$0] + ($0.children ?? []) }
        for item in flat where item.isEnabled && !item.type.isContainer {
            guard let config = item.keyboardShortcut,
                  seen.insert(config).inserted else { continue }

            let keyCode = keyCodeForString(config.key)
            guard keyCode != UInt32.max else { continue }

            let carbonID: UInt32
            if let existing = itemUUIDToID[item.id] {
                carbonID = existing
            } else {
                carbonID = nextHotkeyID
                nextHotkeyID += 1
                itemUUIDToID[item.id] = carbonID
            }

            var hotKeyID = EventHotKeyID()
            hotKeyID.signature = Self.hotkeySignature
            hotKeyID.id = carbonID

            var ref: EventHotKeyRef?
            let status = RegisterEventHotKey(
                keyCode,
                carbonModifiers(for: config),
                hotKeyID,
                GetApplicationEventTarget(),
                0,
                &ref
            )

            if status == noErr, let ref = ref {
                itemHotkeyRefs[carbonID] = ref
                idToItemUUID[carbonID] = item.id
            }
        }
    }

    func unregisterAllItemHotkeys() {
        for ref in itemHotkeyRefs.values {
            UnregisterEventHotKey(ref)
        }
        itemHotkeyRefs.removeAll()
        idToItemUUID.removeAll()
        // itemUUIDToID is kept so ids stay stable and are never reused
    }

    private func ensureEventHandler() {
        guard eventHandler == nil else { return }

        var eventType = EventTypeSpec()
        eventType.eventClass = OSType(kEventClassKeyboard)
        eventType.eventKind = UInt32(kEventHotKeyPressed)

        let handlerBlock: EventHandlerUPP = { _, event, userData -> OSStatus in
            guard let userData = userData, let event = event else { return noErr }
            let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()

            var hotKeyID = EventHotKeyID()
            GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )
            let id = hotKeyID.id

            Task { @MainActor in
                if id == HotkeyManager.menuHotkeyID {
                    manager.onGlobalHotkeyPressed?()
                } else if let uuid = manager.idToItemUUID[id] {
                    manager.onItemHotkeyPressed?(uuid)
                }
            }

            return noErr
        }

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetApplicationEventTarget(),
            handlerBlock,
            1,
            &eventType,
            selfPtr,
            &eventHandler
        )
    }

    private func carbonModifiers(for config: KeyboardShortcutConfig) -> UInt32 {
        var modifiers: UInt32 = 0
        for modifier in config.modifiers {
            switch modifier {
            case .command:
                modifiers |= UInt32(cmdKey)
            case .option:
                modifiers |= UInt32(optionKey)
            case .control:
                modifiers |= UInt32(controlKey)
            case .shift:
                modifiers |= UInt32(shiftKey)
            }
        }
        return modifiers
    }

    private static let keyMap: [String: UInt32] = [
        "A": 0x00, "S": 0x01, "D": 0x02, "F": 0x03,
        "H": 0x04, "G": 0x05, "Z": 0x06, "X": 0x07,
        "C": 0x08, "V": 0x09, "B": 0x0B, "Q": 0x0C,
        "W": 0x0D, "E": 0x0E, "R": 0x0F, "Y": 0x10,
        "T": 0x11, "1": 0x12, "2": 0x13, "3": 0x14,
        "4": 0x15, "6": 0x16, "5": 0x17, "=": 0x18,
        "9": 0x19, "7": 0x1A, "-": 0x1B, "8": 0x1C,
        "0": 0x1D, "]": 0x1E, "O": 0x1F, "U": 0x20,
        "[": 0x21, "I": 0x22, "P": 0x23, "L": 0x25,
        "J": 0x26, "'": 0x27, "K": 0x28, ";": 0x29,
        "\\": 0x2A, ",": 0x2B, "/": 0x2C, "N": 0x2D,
        "M": 0x2E, ".": 0x2F, "`": 0x32,
        "Space": 0x31, "Return": 0x24, "Tab": 0x30,
        "Delete": 0x33, "Escape": 0x35,
        "F1": 0x7A, "F2": 0x78, "F3": 0x63, "F4": 0x76,
        "F5": 0x60, "F6": 0x61, "F7": 0x62, "F8": 0x64,
        "F9": 0x65, "F10": 0x6D, "F11": 0x67, "F12": 0x6F,
    ]

    private static let reverseKeyMap: [UInt32: String] = {
        var map: [UInt32: String] = [:]
        for (key, code) in keyMap {
            map[code] = key
        }
        return map
    }()

    private func keyCodeForString(_ key: String) -> UInt32 {
        return Self.keyMap[key] ?? Self.keyMap[key.uppercased()] ?? UInt32.max
    }

    static func stringForKeyCode(_ keyCode: UInt16) -> String? {
        return reverseKeyMap[UInt32(keyCode)]
    }

    static func configFromEvent(_ event: NSEvent) -> KeyboardShortcutConfig? {
        guard let key = stringForKeyCode(event.keyCode) else { return nil }

        var modifiers: [KeyboardShortcutConfig.Modifier] = []
        if event.modifierFlags.contains(.command) { modifiers.append(.command) }
        if event.modifierFlags.contains(.option) { modifiers.append(.option) }
        if event.modifierFlags.contains(.control) { modifiers.append(.control) }
        if event.modifierFlags.contains(.shift) { modifiers.append(.shift) }

        // Require at least one modifier for a global hotkey
        guard !modifiers.isEmpty else { return nil }

        return KeyboardShortcutConfig(key: key, modifiers: modifiers)
    }

    func cleanup() {
        unregisterGlobalHotkey()
        unregisterAllItemHotkeys()

        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
    }
}
