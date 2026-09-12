import Foundation

enum ActionType: String, Codable, CaseIterable {
    case app = "app"
    case shortcut = "shortcut"
    case folder = "folder"
    case category = "category"

    var displayName: String {
        switch self {
        case .app: return String(localized: "Application")
        case .shortcut: return String(localized: "Shortcut")
        case .folder: return String(localized: "Folder")
        case .category: return String(localized: "Category")
        }
    }

    var defaultIcon: String {
        switch self {
        case .app: return "square.grid.2x2.fill"
        case .shortcut: return "command.square.fill"
        case .folder: return "folder.fill"
        case .category: return "tray.full.fill"
        }
    }

    var isContainer: Bool {
        self == .category
    }
}

struct ActionItem: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var type: ActionType
    var path: String
    var launchArguments: String?
    var icon: String?
    var keyboardShortcut: KeyboardShortcutConfig?
    var isEnabled: Bool
    var children: [ActionItem]?
    var isExpanded: Bool
    var bookmarkData: Data?

    init(
        id: UUID = UUID(),
        name: String,
        type: ActionType,
        path: String = "",
        launchArguments: String? = nil,
        icon: String? = nil,
        keyboardShortcut: KeyboardShortcutConfig? = nil,
        isEnabled: Bool = true,
        children: [ActionItem]? = nil,
        isExpanded: Bool = true,
        bookmarkData: Data? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.path = path
        self.launchArguments = launchArguments
        self.icon = icon
        self.keyboardShortcut = keyboardShortcut
        self.isEnabled = isEnabled
        self.children = type.isContainer ? (children ?? []) : nil
        self.isExpanded = isExpanded
        self.bookmarkData = bookmarkData
    }

    var effectiveIcon: String {
        if let icon = icon, !icon.isEmpty {
            return icon
        }
        return type.defaultIcon
    }

    var isCategory: Bool {
        type == .category
    }
}

struct KeyboardShortcutConfig: Codable, Equatable, Hashable {
    var key: String
    var modifiers: [Modifier]

    enum Modifier: String, Codable, CaseIterable {
        case command = "command"
        case option = "option"
        case control = "control"
        case shift = "shift"
    }

    var displayString: String {
        var parts: [String] = []
        if modifiers.contains(.control) { parts.append("⌃") }
        if modifiers.contains(.option) { parts.append("⌥") }
        if modifiers.contains(.shift) { parts.append("⇧") }
        if modifiers.contains(.command) { parts.append("⌘") }
        parts.append(key.uppercased())
        return parts.joined(separator: " ")
    }
}
