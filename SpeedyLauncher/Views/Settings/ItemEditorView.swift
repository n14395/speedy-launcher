import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct ItemEditorView: View {
    let item: ActionItem?
    let onSave: (ActionItem) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var type: ActionType
    @State private var path: String
    @State private var icon: String
    @State private var showingPicker: Bool = false
    @State private var searchText: String = ""
    @State private var bookmarkData: Data?
    @State private var keyboardShortcut: KeyboardShortcutConfig?
    @State private var launchArguments: String

    init(item: ActionItem?, onSave: @escaping (ActionItem) -> Void) {
        self.item = item
        self.onSave = onSave
        _name = State(initialValue: item?.name ?? "")
        _type = State(initialValue: item?.type ?? .app)
        _path = State(initialValue: item?.path ?? "")
        _icon = State(initialValue: item?.icon ?? "")
        _bookmarkData = State(initialValue: item?.bookmarkData)
        _keyboardShortcut = State(initialValue: item?.keyboardShortcut)
        _launchArguments = State(initialValue: item?.launchArguments ?? "")
    }

    private var previewItem: ActionItem {
        ActionItem(
            name: name.isEmpty ? "New Item" : name,
            type: type,
            path: path,
            icon: icon.isEmpty ? nil : icon
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    Picker("Type:", selection: $type) {
                        ForEach(ActionType.allCases.filter { !$0.isContainer }, id: \.self) { actionType in
                            Label(actionType.displayName, systemImage: actionType.defaultIcon)
                                .tag(actionType)
                        }
                        Divider()
                        ForEach(ActionType.allCases.filter { $0.isContainer }, id: \.self) { actionType in
                            Label(actionType.displayName, systemImage: actionType.defaultIcon)
                                .tag(actionType)
                        }
                    }

                    if type != .category {
                        pathSection
                    }

                    if type == .app {
                        HStack {
                            Text("Command-Line Arguments:")
                            TextField("", text: $launchArguments)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                }

                Section("Name & Icon") {
                    TextField("Name:", text: $name)
                        .textFieldStyle(.roundedBorder)

                    iconSelector
                }

                Section("Preview") {
                    HStack(spacing: 12) {
                        ItemIconView(item: previewItem, size: 40)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(name.isEmpty ? "New Item" : name)
                                .fontWeight(.medium)
                            Text(type.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 4)
                }

                if type != .category {
                    Section("Global Shortcut") {
                        HStack {
                            Text("Shortcut:")
                            Spacer()
                            HotkeyRecorderView(config: $keyboardShortcut)
                        }

                        if let config = keyboardShortcut,
                           let conflictName = StorageService.shared.settings
                               .shortcutConflictName(for: config, excluding: item?.id) {
                            Label("Already used by \(conflictName). The first assignment wins.",
                                  systemImage: "exclamationmark.triangle")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }

                        Text("Runs this action from anywhere, even when the menu is closed.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Save") {
                    saveItem()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty || (type != .category && path.isEmpty))
            }
            .padding()
        }
        .frame(width: 450, height: 620)
    }

    private var hasFilesystemIcon: Bool {
        (type == .app || type == .folder) && !path.isEmpty
    }

    private var filesystemIcon: NSImage? {
        guard hasFilesystemIcon else { return nil }
        let expandedPath = NSString(string: path).expandingTildeInPath
        guard FileManager.default.fileExists(atPath: expandedPath) else { return nil }
        return NSWorkspace.shared.icon(forFile: expandedPath)
    }

    @ViewBuilder
    private var iconSelector: some View {
        HStack(spacing: 8) {
            Text("Icon:")

            Button {
                showingPicker = true
            } label: {
                iconButtonContent
                    .frame(width: 28, height: 28)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .help("Browse SF Symbols")
            .popover(isPresented: $showingPicker, arrowEdge: .bottom) {
                SFSymbolPickerPopover(selection: $icon, searchText: $searchText) {
                    showingPicker = false
                }
            }

            if !icon.isEmpty {
                Button {
                    icon = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Clear custom icon")
            }

            Text(icon.isEmpty ? "Default" : icon)
                .font(.caption)
                .foregroundStyle(.secondary)
                .onTapGesture {
                    showingPicker = true
                }
        }
    }

    @ViewBuilder
    private var iconButtonContent: some View {
        if !icon.isEmpty {
            Image(systemName: icon)
                .font(.system(size: 18))
        } else if let nsImage = filesystemIcon {
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(2)
        } else {
            Image(systemName: type.defaultIcon)
                .font(.system(size: 18))
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var pathSection: some View {
        switch type {
        case .app:
            HStack {
                Text("Application:")
                Text(path.isEmpty ? "None selected" : path)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                Button("Browse...") {
                    browseForApp()
                }
            }

        case .shortcut:
            VStack(alignment: .leading) {
                TextField("Shortcut Name:", text: $path)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: path) { _, newValue in
                        // Auto-update name to match shortcut name
                        if !newValue.isEmpty {
                            name = newValue
                        }
                    }
                Text("Enter the exact name of the Shortcut from the Shortcuts app")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

        case .folder:
            HStack {
                Text("Folder:")
                Text(path.isEmpty ? "None selected" : path)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                Button("Browse...") {
                    browseForFolder()
                }
            }

        case .category:
            EmptyView()
        }
    }

    private func browseForApp() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: "/Applications")

        if panel.runModal() == .OK, let url = panel.url {
            path = url.path
            name = url.deletingPathExtension().lastPathComponent
        }
    }

    private func browseForFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            path = url.path
            name = url.lastPathComponent

            // Create security-scoped bookmark for sandbox access
            do {
                bookmarkData = try url.bookmarkData(
                    options: .withSecurityScope,
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                )
            } catch {
                print("Failed to create bookmark: \(error)")
                bookmarkData = nil
            }
        }
    }

    private func saveItem() {
        let newItem = ActionItem(
            id: item?.id ?? UUID(),
            name: name,
            type: type,
            path: type == .category ? "" : path,
            launchArguments: type == .app && !launchArguments.isEmpty ? launchArguments : nil,
            icon: icon.isEmpty ? nil : icon,
            keyboardShortcut: type == .category ? nil : keyboardShortcut,
            isEnabled: item?.isEnabled ?? true,
            children: item?.children,
            isExpanded: item?.isExpanded ?? true,
            bookmarkData: type == .folder ? bookmarkData : nil
        )
        onSave(newItem)
        dismiss()
    }
}

#Preview {
    ItemEditorView(item: nil) { _ in }
}
