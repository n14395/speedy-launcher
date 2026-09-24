// Copyright 2026 Nick Fay
// SPDX-License-Identifier: Apache-2.0

import SwiftUI

struct MenuPopoverView: View {
    @ObservedObject var storage: StorageService
    @Environment(\.openSettings) private var openSettings

    @State private var errorMessage: String?
    @State private var showError = false
    @State private var draggedItem: ActionItem?
    @State private var keyMonitor: Any?

    private var hasExpandedCategory: Bool {
        storage.settings.items.contains { $0.isCategory && $0.isExpanded }
    }

    private var showIndexLabels: Bool {
        storage.settings.enableKeyboardShortcuts && !hasExpandedCategory
    }

    private var showChildIndexLabels: Bool {
        storage.settings.enableKeyboardShortcuts
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                if storage.settings.items.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(storage.settings.items.enumerated()), id: \.element.id) { index, item in
                            if item.isCategory {
                                CategorySection(
                                    category: item,
                                    index: index + 1,
                                    showIndex: showIndexLabels,
                                    showChildIndex: showChildIndexLabels,
                                    onToggle: { storage.toggleCategoryExpanded(item) },
                                    onExecute: { childItem in
                                        executeAction(childItem)
                                    }
                                )
                            } else {
                                ActionRowView(item: item, index: index + 1, showIndex: showIndexLabels) {
                                    executeAction(item)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Divider()
                    .padding(.horizontal, 8)

                footerButtons
            }

            if showError {
                errorOverlay
            }
        }
        .frame(width: 280)
        .frame(maxHeight: 500)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear {
            collapseAllCategories()
            setupKeyMonitor()
        }
        .onReceive(NotificationCenter.default.publisher(for: .popoverWillOpen)) { _ in
            collapseAllCategories()
            setupKeyMonitor()
        }
        .onReceive(NotificationCenter.default.publisher(for: .popoverWillClose)) { _ in
            removeKeyMonitor()
        }
        .onDisappear {
            removeKeyMonitor()
        }
    }

    private var errorOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32))
                .foregroundStyle(.yellow)

            Text("Error")
                .font(.headline)

            Text(errorMessage ?? "An unknown error occurred")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("OK") {
                showError = false
                errorMessage = nil
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial)
    }

    private func collapseAllCategories() {
        for item in storage.settings.items where item.isCategory && item.isExpanded {
            storage.toggleCategoryExpanded(item)
        }
    }

    private func setupKeyMonitor() {
        removeKeyMonitor()
        guard storage.settings.enableKeyboardShortcuts else { return }
        let storageRef = storage
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard let characters = event.charactersIgnoringModifiers,
                  let digit = Int(characters),
                  digit >= 0 && digit <= 9 else {
                return event
            }

            // Map 0 to index 10, otherwise use digit as-is
            let index = digit == 0 ? 10 : digit

            // Check if any category is expanded
            if let expandedCategory = storageRef.settings.items.first(where: { $0.isCategory && $0.isExpanded }) {
                // Select from the expanded category's children
                if let children = expandedCategory.children, index <= children.count {
                    let item = children[index - 1]
                    if item.isEnabled {
                        Task {
                            do {
                                try await ActionExecutor.shared.execute(item)
                                await MainActor.run {
                                    NSApp.keyWindow?.close()
                                }
                            } catch {
                                // Error handling is limited in this context
                            }
                        }
                    }
                    return nil
                }
            } else {
                // Select from top-level items
                if index <= storageRef.settings.items.count {
                    let item = storageRef.settings.items[index - 1]
                    if item.isCategory {
                        storageRef.toggleCategoryExpanded(item)
                    } else if item.isEnabled {
                        Task {
                            do {
                                try await ActionExecutor.shared.execute(item)
                                await MainActor.run {
                                    NSApp.keyWindow?.close()
                                }
                            } catch {
                                // Error handling is limited in this context
                            }
                        }
                    }
                    return nil
                }
            }
            return event
        }
    }

    private func removeKeyMonitor() {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
    }

    private func dismissPopover() {
        NSApp.keyWindow?.close()
        DispatchQueue.main.async {
            // Activate Finder to remove focus from menu bar
            if let finder = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == "com.apple.finder" }) {
                finder.activate(options: [])
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 32))
                .foregroundStyle(.tertiary)

            Text("No Actions")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Open Settings to add your first action")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }

    private var footerButtons: some View {
        HStack {
            Button {
                NSApp.keyWindow?.close()
                openSettings()
                NSApp.activate(ignoringOtherApps: true)
            } label: {
                Label("Settings", systemImage: "gear")
                    .font(.system(size: 12))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Label("Quit", systemImage: "power")
                    .font(.system(size: 12))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .focusEffectDisabled()
    }

    private func executeAction(_ item: ActionItem) {
        Task {
            do {
                try await ActionExecutor.shared.execute(item)
                dismissPopover()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

struct CategorySection: View {
    let category: ActionItem
    let index: Int
    let showIndex: Bool
    var showChildIndex: Bool = true
    let onToggle: () -> Void
    let onExecute: (ActionItem) -> Void

    var body: some View {
        VStack(spacing: 0) {
            CategoryHeaderView(category: category, index: index, showIndex: showIndex, onToggle: onToggle)

            if category.isExpanded {
                VStack(spacing: 0) {
                    if let children = category.children {
                        ForEach(Array(children.enumerated()), id: \.element.id) { childIndex, item in
                            ActionRowView(item: item, index: childIndex + 1, showIndex: showChildIndex) {
                                onExecute(item)
                            }
                            .padding(.leading, 16)
                        }
                    }
                }
            }
        }
    }
}

struct MenuDropDelegate: DropDelegate {
    let item: ActionItem
    let items: [ActionItem]
    @Binding var draggedItem: ActionItem?
    let onReorder: (IndexSet, Int) -> Void
    let onMoveToCategory: ((UUID, UUID) -> Void)?

    func performDrop(info: DropInfo) -> Bool {
        draggedItem = nil
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let draggedItem = draggedItem,
              draggedItem.id != item.id else { return }

        // If dropping on a category and we have a handler for it
        if item.isCategory, let moveToCategory = onMoveToCategory {
            // Don't move a category into itself
            if !draggedItem.isCategory {
                moveToCategory(draggedItem.id, item.id)
            }
            return
        }

        // Reorder within the list
        guard let fromIndex = items.firstIndex(where: { $0.id == draggedItem.id }),
              let toIndex = items.firstIndex(where: { $0.id == item.id }) else { return }

        if fromIndex != toIndex {
            let destinationIndex = fromIndex < toIndex ? toIndex + 1 : toIndex
            onReorder(IndexSet(integer: fromIndex), destinationIndex)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}

#Preview {
    MenuPopoverView(storage: StorageService.shared)
}
