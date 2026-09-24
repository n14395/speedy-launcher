// Copyright 2026 Nick Fay
// SPDX-License-Identifier: Apache-2.0

import SwiftUI
import ServiceManagement

extension Notification.Name {
    static let menuBarIconChanged = Notification.Name("menuBarIconChanged")
    static let popoverWillOpen = Notification.Name("popoverWillOpen")
    static let popoverWillClose = Notification.Name("popoverWillClose")
}

struct SettingsView: View {
    @ObservedObject var storage: StorageService
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ActionsSettingsView(storage: storage)
                .tabItem {
                    Label("Actions", systemImage: "list.bullet")
                }
                .tag(0)

            GeneralSettingsView(storage: storage)
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(1)
        }
        .frame(width: 550, height: 450)
    }
}

struct EditorState: Identifiable {
    let id = UUID()
    let item: ActionItem?
    let targetCategoryID: UUID?
}

struct ActionsSettingsView: View {
    @ObservedObject var storage: StorageService
    @State private var editorState: EditorState?
    @State private var highlight: DropZone?

    /// Identifies one drop zone. Two zones can share a destination (the gap
    /// above a row and the row itself both insert before it), so `kind`
    /// keeps their identities distinct — otherwise hovering one would light
    /// up both.
    private struct DropZone: Equatable {
        enum Kind { case gap, row, category, end }
        let kind: Kind
        let target: DropTarget
    }

    var body: some View {
        VStack(spacing: 0) {
            itemsList
            Divider()
            toolbar
        }
        .sheet(item: $editorState) { state in
            ItemEditorView(
                item: state.item,
                onSave: { item in
                    if state.item != nil {
                        storage.updateItem(item)
                    } else if let categoryID = state.targetCategoryID {
                        storage.addItem(item, toCategory: categoryID)
                    } else {
                        storage.addItem(item)
                    }
                }
            )
        }
    }

    private func openEditor(for item: ActionItem? = nil, inCategory categoryID: UUID? = nil) {
        editorState = EditorState(item: item, targetCategoryID: categoryID)
    }

    // MARK: - Drag and Drop

    /// Applies a drop and reports whether it was handled. The payload is the
    /// dragged item's UUID string.
    private func handleDrop(_ payload: [String], to target: DropTarget) -> Bool {
        highlight = nil
        guard let idString = payload.first, let itemID = UUID(uuidString: idString) else { return false }
        withAnimation(.easeInOut(duration: 0.15)) {
            storage.moveItem(itemID, to: target)
        }
        return true
    }

    private func setHighlight(_ zone: DropZone, targeted: Bool) {
        if targeted {
            highlight = zone
        } else if highlight == zone {
            // Only clear our own highlight: when the pointer moves between
            // zones, the new zone reports `true` before the old reports
            // `false`, and clearing unconditionally would erase it.
            highlight = nil
        }
    }

    /// A thin strip between rows that accepts a drop at a precise position.
    /// These are what make it possible to drop *before* a category header,
    /// which itself means "move into this category".
    ///
    /// The strip's height never changes — the indicator is drawn as an
    /// overlay. Resizing it on hover would reflow every row below, sliding
    /// the zone out from under the pointer and making the drag flicker.
    @ViewBuilder
    private func dropGap(target: DropTarget, indented: Bool = false) -> some View {
        let zone = DropZone(kind: .gap, target: target)
        Color.clear
            .frame(height: 10)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .center) {
                if highlight == zone {
                    Capsule()
                        .fill(Color.accentColor)
                        .frame(height: 3)
                        .padding(.leading, indented ? 40 : 10)
                        .padding(.trailing, 10)
                }
            }
            .contentShape(Rectangle())
            .dropDestination(for: String.self) { payload, _ in
                handleDrop(payload, to: target)
            } isTargeted: { targeted in
                setHighlight(zone, targeted: targeted)
            }
            .animation(.easeInOut(duration: 0.12), value: highlight)
    }

    private var itemsList: some View {
        Group {
            if storage.settings.items.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "plus.square.dashed")
                        .font(.system(size: 48))
                        .foregroundStyle(.tertiary)
                    Text("No actions yet")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Click + below to add your first action")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(storage.settings.items.enumerated()), id: \.element.id) { index, item in
                            dropGap(target: .topLevel(index: index))

                            if item.isCategory {
                                categoryRow(item)
                            } else {
                                draggableRow(
                                    itemRow(item, indented: false, parentCategory: nil),
                                    item: item,
                                    dropTarget: .topLevel(index: index)
                                )
                            }
                        }

                        // Trailing zone: drop here to move an item to the end.
                        endDropZone
                    }
                    .padding(.vertical, 4)
                }
                .focusEffectDisabled()
            }
        }
    }

    /// Drop area below the last row: moves the item to the end of the list.
    private var endDropZone: some View {
        let zone = DropZone(kind: .end, target: .topLevel(index: storage.settings.items.count))
        return Color.clear
            .frame(minHeight: 24)
            .frame(maxWidth: .infinity)
            .overlay(alignment: .top) {
                if highlight == zone {
                    Capsule()
                        .fill(Color.accentColor)
                        .frame(height: 3)
                        .padding(.horizontal, 10)
                }
            }
            .contentShape(Rectangle())
            .dropDestination(for: String.self) { payload, _ in
                handleDrop(payload, to: .topLevel(index: storage.settings.items.count))
            } isTargeted: { targeted in
                setHighlight(zone, targeted: targeted)
            }
    }

    /// A category header plus, when expanded, its children with their own
    /// drop zones.
    ///
    /// There is deliberately no gap after the last child: it would sit
    /// directly against the next top-level gap, giving two adjacent invisible
    /// strips with very different meanings ("append to this category" vs
    /// "place after this category"). Appending is done by dropping on the
    /// header instead.
    @ViewBuilder
    private func categoryRow(_ category: ActionItem) -> some View {
        let zone = DropZone(kind: .category, target: .intoCategory(id: category.id))

        categoryHeaderRow(category)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(highlight == zone ? Color.accentColor.opacity(0.25) : Color.clear)
                    .padding(.horizontal, 6)
            )
            .contentShape(Rectangle())
            .draggable(category.id.uuidString)
            .dropDestination(for: String.self) { payload, _ in
                handleDrop(payload, to: .intoCategory(id: category.id))
            } isTargeted: { targeted in
                setHighlight(zone, targeted: targeted)
            }

        if category.isExpanded, let children = category.children {
            ForEach(Array(children.enumerated()), id: \.element.id) { childIndex, child in
                dropGap(target: .inCategory(id: category.id, index: childIndex), indented: true)

                draggableRow(
                    itemRow(child, indented: true, parentCategory: category),
                    item: child,
                    dropTarget: .inCategory(id: category.id, index: childIndex),
                    indented: true
                )
            }
        }
    }

    /// Wraps a row so it can be dragged, and so dropping onto it inserts the
    /// dragged item immediately before it.
    @ViewBuilder
    private func draggableRow(
        _ content: some View,
        item: ActionItem,
        dropTarget: DropTarget,
        indented: Bool = false
    ) -> some View {
        let zone = DropZone(kind: .row, target: dropTarget)

        content
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
            .overlay(alignment: .top) {
                if highlight == zone {
                    Capsule()
                        .fill(Color.accentColor)
                        .frame(height: 3)
                        .padding(.leading, indented ? 40 : 10)
                        .padding(.trailing, 10)
                }
            }
            .draggable(item.id.uuidString)
            .dropDestination(for: String.self) { payload, _ in
                handleDrop(payload, to: dropTarget)
            } isTargeted: { targeted in
                setHighlight(zone, targeted: targeted)
            }
    }

    @ViewBuilder
    private func categoryHeaderRow(_ category: ActionItem) -> some View {
        HStack {
            Button {
                storage.toggleCategoryExpanded(category)
            } label: {
                Image(systemName: category.isExpanded ? "chevron.down" : "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 16)
            }
            .buttonStyle(.plain)

            ItemIconView(item: category, size: 18)
            Text(category.name)
                .fontWeight(.medium)
            Spacer()
            Text("\(category.children?.count ?? 0) items")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            openEditor(for: category)
        }
        .onTapGesture(count: 1) {
            storage.toggleCategoryExpanded(category)
        }
        .contextMenu {
            Button("Edit Category") {
                openEditor(for: category)
            }
            Button("Add Item to Category") {
                openEditor(inCategory: category.id)
            }
            Divider()
            Button("Delete Category", role: .destructive) {
                storage.deleteItem(category)
            }
        }
    }

    @ViewBuilder
    private func itemRow(_ item: ActionItem, indented: Bool, parentCategory: ActionItem? = nil) -> some View {
        HStack {
            if indented {
                Spacer().frame(width: 20)
            }
            ItemIconView(item: item, size: 18)
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(item.name)
                        .foregroundStyle(item.isEnabled ? .primary : .secondary)
                    if !item.isEnabled {
                        Text("(Disabled)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                if let subtitle = itemSubtitle(item) {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
            Spacer()
            if let shortcut = item.keyboardShortcut {
                ShortcutBadge(shortcut: shortcut)
            }
            Text(item.type.displayName)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(minWidth: 80, alignment: .trailing)
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            openEditor(for: item)
        }
        .contextMenu {
            Button("Edit") {
                openEditor(for: item)
            }
            if let parent = parentCategory {
                Button("Move to Top Level") {
                    if let categoryIndex = storage.settings.items.firstIndex(where: { $0.id == parent.id }) {
                        storage.moveItemOutOfCategory(item.id, fromCategoryID: parent.id, toIndex: categoryIndex + 1)
                    }
                }
            }
            Divider()
            Button("Delete", role: .destructive) {
                storage.deleteItem(item)
            }
        }
    }

    private func itemSubtitle(_ item: ActionItem) -> String? {
        switch item.type {
        case .shortcut: return "Shortcut: \(item.path)"
        case .category: return nil
        default: return item.path.isEmpty ? nil : item.path
        }
    }

    private var toolbar: some View {
        HStack {
            Button {
                openEditor()
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(.borderless)
            .help("Add new item")

            Spacer()
        }
        .padding(8)
        .focusEffectDisabled()
    }
}

struct ItemListRow: View {
    let item: ActionItem

    var body: some View {
        HStack {
            Image(systemName: item.effectiveIcon)
                .foregroundStyle(item.isEnabled ? .primary : .tertiary)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .foregroundStyle(item.isEnabled ? .primary : .secondary)
                Text(item.path)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
            Spacer()
            Text(item.type.displayName)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct GeneralSettingsView: View {
    @ObservedObject var storage: StorageService
    @ObservedObject var hotkeyManager = HotkeyManager.shared

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Toggle("Enable Keyboard Shortcuts", isOn: keyboardShortcutsBinding)
                    .help("Enable global hotkey and menu item shortcuts (1-9, 0)")

                HStack {
                    Text("Global Hotkey:")
                    Spacer()
                    HotkeyRecorderView(config: hotkeyBinding)
                }
                .disabled(!storage.settings.enableKeyboardShortcuts)

                if storage.settings.enableKeyboardShortcuts {
                    hotkeyStatus
                }

                IconSelectorView(
                    itemDescription: "Menu Bar Icon:",
                    defaultIcon: defaultMenuBarIcon,
                    customIcon: menuBarIconBinding
                )

                Toggle("Launch at Login", isOn: launchAtLoginBinding)

                HStack {
                    Button("Export Configuration...") {
                        exportConfiguration()
                    }
                    Button("Import Configuration...") {
                        importConfiguration()
                    }
                }

                // SpeedyLauncher is a menu-bar agent (LSUIElement) with no persistent window
                // to host the native review prompt, so we offer a manual "Rate" affordance that
                // links to the Mac App Store product page. Apple allows this for a
                // manual button (unlike requestReview(), which must not be tied to a button).
                Button("Rate SpeedyLauncher on the App Store...") {
                    if let url = URL(string: "macappstore://apps.apple.com/app/id6757640569?action=write-review") {
                        NSWorkspace.shared.open(url)
                    }
                }

                #if SPARKLE
                SparkleCheckForUpdatesButton()
                #endif
            }
            .formStyle(.grouped)

            Text("\u{00A9} n14395 2026")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
    }

    private var keyboardShortcutsBinding: Binding<Bool> {
        Binding(
            get: { storage.settings.enableKeyboardShortcuts },
            set: { newValue in
                storage.settings.enableKeyboardShortcuts = newValue
                if newValue {
                    hotkeyManager.registerGlobalHotkey(storage.settings.globalHotkey)
                } else {
                    hotkeyManager.unregisterGlobalHotkey()
                }
            }
        )
    }

    private var hotkeyBinding: Binding<KeyboardShortcutConfig?> {
        Binding(
            get: { storage.settings.globalHotkey },
            set: {
                storage.settings.globalHotkey = $0
                if storage.settings.enableKeyboardShortcuts {
                    hotkeyManager.registerGlobalHotkey($0)
                }
            }
        )
    }

    @ViewBuilder
    private var hotkeyStatus: some View {
        if hotkeyManager.isGlobalHotkeyEnabled {
            Label("Hotkey registered", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.caption)
        } else {
            Label("Hotkey not registered", systemImage: "xmark.circle.fill")
                .foregroundStyle(.red)
                .font(.caption)
        }
    }

    private let defaultMenuBarIcon = "bookmark"

    private var menuBarIconBinding: Binding<String> {
        Binding(
            get: {
                let current = storage.settings.menuBarIconName
                return current == defaultMenuBarIcon ? "" : current
            },
            set: {
                storage.settings.menuBarIconName = $0.isEmpty ? defaultMenuBarIcon : $0
                NotificationCenter.default.post(name: .menuBarIconChanged, object: nil)
            }
        )
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: {
                SMAppService.mainApp.status == .enabled
            },
            set: { newValue in
                do {
                    if newValue {
                        try SMAppService.mainApp.register()
                    } else {
                        try SMAppService.mainApp.unregister()
                    }
                    storage.settings.launchAtLogin = newValue
                } catch {
                    print("Failed to update launch at login: \(error)")
                }
            }
        )
    }

    private func exportConfiguration() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "SpeedyLauncher-config.json"

        if panel.runModal() == .OK, let url = panel.url {
            try? storage.exportSettings(to: url)
        }
    }

    private func importConfiguration() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            try? storage.importSettings(from: url)
        }
    }
}


#Preview {
    SettingsView(storage: StorageService.shared)
}
