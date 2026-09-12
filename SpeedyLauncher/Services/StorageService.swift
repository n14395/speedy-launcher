import Foundation

// MARK: - Migration Types for handling legacy config formats

/// Legacy action type enum that includes removed script types for migration
private enum LegacyActionType: String, Codable {
    case app = "app"
    case shellScript = "shellScript"
    case scriptFile = "scriptFile"
    case shortcut = "shortcut"
    case folder = "folder"
    case category = "category"

    var isSupported: Bool {
        switch self {
        case .shellScript, .scriptFile:
            return false
        default:
            return true
        }
    }

    var modernType: ActionType? {
        switch self {
        case .app: return .app
        case .shortcut: return .shortcut
        case .folder: return .folder
        case .category: return .category
        case .shellScript, .scriptFile: return nil
        }
    }
}

/// Legacy action item for migration
private struct LegacyActionItem: Codable {
    let id: UUID
    var name: String
    var type: LegacyActionType
    var path: String
    var icon: String?
    var keyboardShortcut: KeyboardShortcutConfig?
    var isEnabled: Bool
    var children: [LegacyActionItem]?
    var isExpanded: Bool
    var bookmarkData: Data?

    func toModernItem() -> ActionItem? {
        guard let modernType = type.modernType else { return nil }

        let modernChildren = children?.compactMap { $0.toModernItem() }

        return ActionItem(
            id: id,
            name: name,
            type: modernType,
            path: path,
            icon: icon,
            keyboardShortcut: keyboardShortcut,
            isEnabled: isEnabled,
            children: modernChildren,
            isExpanded: isExpanded,
            bookmarkData: bookmarkData
        )
    }
}

/// Legacy settings for migration
private struct LegacyAppSettings: Codable {
    var items: [LegacyActionItem]
    var globalHotkey: KeyboardShortcutConfig?
    var launchAtLogin: Bool
    var showMenuBarIcon: Bool
    var menuBarIconName: String
    var enableKeyboardShortcuts: Bool

    func toModernSettings() -> AppSettings {
        let modernItems = items.compactMap { $0.toModernItem() }
        return AppSettings(
            items: modernItems,
            globalHotkey: globalHotkey,
            launchAtLogin: launchAtLogin,
            showMenuBarIcon: showMenuBarIcon,
            menuBarIconName: menuBarIconName,
            enableKeyboardShortcuts: enableKeyboardShortcuts
        )
    }
}

/// Where a dragged item should land. Expressed as a destination rather than a
/// sequence of moves so the drop is a single, testable operation.
enum DropTarget: Equatable {
    /// Insert at this index in the top-level list.
    case topLevel(index: Int)
    /// Append to the end of this category.
    case intoCategory(id: UUID)
    /// Insert at this index among the category's children.
    case inCategory(id: UUID, index: Int)
}

@MainActor
class StorageService: ObservableObject {
    static let shared = StorageService()

    @Published var settings: AppSettings {
        didSet {
            saveSettings()
        }
    }

    private let fileManager = FileManager.default
    private var configURL: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("SpeedyLauncher", isDirectory: true)

        if !fileManager.fileExists(atPath: appFolder.path) {
            try? fileManager.createDirectory(at: appFolder, withIntermediateDirectories: true)
        }

        return appFolder.appendingPathComponent("config.json")
    }

    private init() {
        self.settings = AppSettings.default
        migrateLegacyFolderIfNeeded()
        loadSettings()
    }

    /// The app was renamed from SpeedLauncher to SpeedyLauncher; move the old
    /// Application Support folder so existing users keep their configuration.
    private func migrateLegacyFolderIfNeeded() {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let newFolder = appSupport.appendingPathComponent("SpeedyLauncher", isDirectory: true)
        let legacyFolder = appSupport.appendingPathComponent("SpeedLauncher", isDirectory: true)
        if !fileManager.fileExists(atPath: newFolder.path),
           fileManager.fileExists(atPath: legacyFolder.path) {
            try? fileManager.moveItem(at: legacyFolder, to: newFolder)
        }
    }

    func loadSettings() {
        guard fileManager.fileExists(atPath: configURL.path) else {
            settings = AppSettings.default
            return
        }

        do {
            let data = try Data(contentsOf: configURL)
            let decoder = JSONDecoder()

            // Try to decode as modern format first
            do {
                settings = try decoder.decode(AppSettings.self, from: data)
            } catch {
                // Fall back to legacy format and migrate
                print("Migrating legacy config format...")
                let legacySettings = try decoder.decode(LegacyAppSettings.self, from: data)
                settings = legacySettings.toModernSettings()
                print("Migration complete. Removed unsupported action types (shell scripts, script files).")
            }
        } catch {
            print("Failed to load settings: \(error)")
            settings = AppSettings.default
        }
    }

    func saveSettings() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(settings)
            try data.write(to: configURL, options: .atomic)
        } catch {
            print("Failed to save settings: \(error)")
        }
    }

    func exportSettings(to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(settings)
        try data.write(to: url, options: .atomic)
    }

    func importSettings(from url: URL) throws {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()

        // Try to decode as modern format first
        do {
            settings = try decoder.decode(AppSettings.self, from: data)
        } catch {
            // Fall back to legacy format and migrate
            let legacySettings = try decoder.decode(LegacyAppSettings.self, from: data)
            settings = legacySettings.toModernSettings()
            print("Imported legacy config. Removed unsupported action types (shell scripts, script files).")
        }
    }

    // MARK: - Item Management

    func addItem(_ item: ActionItem) {
        settings.items.append(item)
    }

    func addItem(_ item: ActionItem, toCategory categoryID: UUID) {
        if let index = settings.items.firstIndex(where: { $0.id == categoryID }) {
            if settings.items[index].children != nil {
                settings.items[index].children?.append(item)
            }
        }
    }

    func updateItem(_ item: ActionItem) {
        if let index = settings.items.firstIndex(where: { $0.id == item.id }) {
            settings.items[index] = item
        } else {
            for i in settings.items.indices {
                if let childIndex = settings.items[i].children?.firstIndex(where: { $0.id == item.id }) {
                    settings.items[i].children?[childIndex] = item
                    return
                }
            }
        }
    }

    func deleteItem(_ item: ActionItem) {
        if let index = settings.items.firstIndex(where: { $0.id == item.id }) {
            settings.items.remove(at: index)
        } else {
            for i in settings.items.indices {
                settings.items[i].children?.removeAll { $0.id == item.id }
            }
        }
    }

    func moveItem(from source: IndexSet, to destination: Int) {
        settings.items.move(fromOffsets: source, toOffset: destination)
    }

    func reorderItem(_ itemID: UUID, toIndex: Int) {
        guard let currentIndex = settings.items.firstIndex(where: { $0.id == itemID }) else { return }
        let item = settings.items.remove(at: currentIndex)
        let newIndex = currentIndex < toIndex ? toIndex - 1 : toIndex
        settings.items.insert(item, at: min(newIndex, settings.items.count))
    }

    func moveItemInCategory(_ categoryID: UUID, from source: IndexSet, to destination: Int) {
        if let index = settings.items.firstIndex(where: { $0.id == categoryID }) {
            settings.items[index].children?.move(fromOffsets: source, toOffset: destination)
        }
    }

    func reorderItemInCategory(_ categoryID: UUID, itemID: UUID, targetItemID: UUID) {
        guard let categoryIndex = settings.items.firstIndex(where: { $0.id == categoryID }),
              let children = settings.items[categoryIndex].children,
              let fromIndex = children.firstIndex(where: { $0.id == itemID }),
              let toIndex = children.firstIndex(where: { $0.id == targetItemID }) else { return }

        let destinationIndex = fromIndex < toIndex ? toIndex + 1 : toIndex
        settings.items[categoryIndex].children?.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: destinationIndex)
    }

    func moveItemToCategory(_ itemID: UUID, categoryID: UUID) {
        guard let itemIndex = settings.items.firstIndex(where: { $0.id == itemID }) else { return }
        let item = settings.items.remove(at: itemIndex)

        if let categoryIndex = settings.items.firstIndex(where: { $0.id == categoryID }) {
            if settings.items[categoryIndex].children == nil {
                settings.items[categoryIndex].children = []
            }
            settings.items[categoryIndex].children?.append(item)
        }
    }

    func moveItemOutOfCategory(_ itemID: UUID, fromCategoryID categoryID: UUID, toIndex: Int) {
        guard let categoryIndex = settings.items.firstIndex(where: { $0.id == categoryID }) else { return }
        guard let childIndex = settings.items[categoryIndex].children?.firstIndex(where: { $0.id == itemID }) else { return }

        let item = settings.items[categoryIndex].children?.remove(at: childIndex)
        if let item = item {
            let insertIndex = min(toIndex, settings.items.count)
            settings.items.insert(item, at: insertIndex)
        }
    }

    // MARK: - Drag and Drop

    private enum ItemLocation {
        case topLevel(index: Int)
        case inCategory(categoryIndex: Int, childIndex: Int)
    }

    private func locate(_ itemID: UUID) -> ItemLocation? {
        if let index = settings.items.firstIndex(where: { $0.id == itemID }) {
            return .topLevel(index: index)
        }
        for (categoryIndex, category) in settings.items.enumerated() {
            if let childIndex = category.children?.firstIndex(where: { $0.id == itemID }) {
                return .inCategory(categoryIndex: categoryIndex, childIndex: childIndex)
            }
        }
        return nil
    }

    /// Moves an item to `target`, wherever it currently lives. Handles the
    /// index shifting that removal causes, so callers pass the destination
    /// they see on screen.
    func moveItem(_ itemID: UUID, to target: DropTarget) {
        guard let location = locate(itemID) else { return }

        let item: ActionItem
        let sourceCategoryID: UUID?
        switch location {
        case .topLevel(let index):
            item = settings.items[index]
            sourceCategoryID = nil
        case .inCategory(let categoryIndex, let childIndex):
            guard let child = settings.items[categoryIndex].children?[childIndex] else { return }
            item = child
            sourceCategoryID = settings.items[categoryIndex].id
        }

        // Categories live at the top level only; nesting isn't supported.
        // Rather than silently ignoring a drop the UI highlighted as valid,
        // land the category at the destination category's own position.
        var target = target
        if item.isCategory {
            switch target {
            case .topLevel:
                break
            case .intoCategory(let categoryID), .inCategory(let categoryID, _):
                guard let categoryIndex = settings.items.firstIndex(where: { $0.id == categoryID }) else { return }
                target = .topLevel(index: categoryIndex)
            }
        }

        func removeFromSource() {
            switch location {
            case .topLevel(let index):
                settings.items.remove(at: index)
            case .inCategory(let categoryIndex, let childIndex):
                settings.items[categoryIndex].children?.remove(at: childIndex)
            }
        }

        switch target {
        case .topLevel(var index):
            if case .topLevel(let current) = location {
                // Dropping just before or just after itself changes nothing.
                if current == index || current + 1 == index { return }
                if current < index { index -= 1 }
            }
            removeFromSource()
            settings.items.insert(item, at: max(0, min(index, settings.items.count)))

        case .intoCategory(let categoryID):
            guard settings.items.contains(where: { $0.id == categoryID && $0.isCategory }) else { return }
            removeFromSource()
            // Re-find after removal: the category's index may have shifted.
            guard let categoryIndex = settings.items.firstIndex(where: { $0.id == categoryID }) else { return }
            if settings.items[categoryIndex].children == nil {
                settings.items[categoryIndex].children = []
            }
            settings.items[categoryIndex].children?.append(item)

        case .inCategory(let categoryID, var index):
            guard settings.items.contains(where: { $0.id == categoryID && $0.isCategory }) else { return }
            if sourceCategoryID == categoryID, case .inCategory(_, let currentChild) = location {
                if currentChild == index || currentChild + 1 == index { return }
                if currentChild < index { index -= 1 }
            }
            removeFromSource()
            guard let categoryIndex = settings.items.firstIndex(where: { $0.id == categoryID }) else { return }
            if settings.items[categoryIndex].children == nil {
                settings.items[categoryIndex].children = []
            }
            let childCount = settings.items[categoryIndex].children?.count ?? 0
            settings.items[categoryIndex].children?.insert(item, at: max(0, min(index, childCount)))
        }
    }

    func toggleCategoryExpanded(_ item: ActionItem) {
        if let index = settings.items.firstIndex(where: { $0.id == item.id }) {
            settings.items[index].isExpanded.toggle()
        }
    }

    func findItem(byID id: UUID) -> ActionItem? {
        if let item = settings.items.first(where: { $0.id == id }) {
            return item
        }
        for category in settings.items where category.isCategory {
            if let child = category.children?.first(where: { $0.id == id }) {
                return child
            }
        }
        return nil
    }

    func findParentCategory(forItemID id: UUID) -> ActionItem? {
        for category in settings.items where category.isCategory {
            if category.children?.contains(where: { $0.id == id }) == true {
                return category
            }
        }
        return nil
    }
}
