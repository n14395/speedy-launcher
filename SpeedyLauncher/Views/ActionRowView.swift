import SwiftUI

struct ActionRowView: View {
    let item: ActionItem
    let index: Int
    var showIndex: Bool = true
    let onExecute: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: onExecute) {
            HStack(spacing: 10) {
                ItemIconView(item: item, size: 20)

                Text(item.name)
                    .font(.system(size: 13))
                    .foregroundStyle(item.isEnabled ? .primary : .secondary)

                Spacer()

                if let shortcut = item.keyboardShortcut {
                    ShortcutBadge(shortcut: shortcut)
                }

                if showIndex && index <= 10 {
                    Text(index == 10 ? "0" : "\(index)")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(.quaternary)
                        )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .focusEffectDisabled()
        .background(isHovering ? Color.accentColor.opacity(0.1) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .onHover { hovering in
            isHovering = hovering
        }
        .opacity(item.isEnabled ? 1.0 : 0.5)
        .disabled(!item.isEnabled)
    }

    @ViewBuilder
    private var typeIndicator: some View {
        switch item.type {
        case .app:
            EmptyView()
        case .shortcut:
            Image(systemName: "command")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        case .folder:
            EmptyView()
        case .category:
            EmptyView()
        }
    }
}

/// Key-combo badge shared by the menu popup rows and the settings list.
struct ShortcutBadge: View {
    let shortcut: KeyboardShortcutConfig

    var body: some View {
        Text(shortcut.displayString)
            .font(.system(size: 11, design: .monospaced))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(.quaternary)
            )
    }
}

#Preview {
    VStack(spacing: 0) {
        ActionRowView(
            item: ActionItem(
                name: "Terminal",
                type: .app,
                path: "/System/Applications/Utilities/Terminal.app"
            ),
            index: 1,
            onExecute: {}
        )
        ActionRowView(
            item: ActionItem(
                name: "Toggle Dark Mode",
                type: .shortcut,
                path: "Toggle Dark Mode",
                keyboardShortcut: KeyboardShortcutConfig(key: "D", modifiers: [.command, .shift])
            ),
            index: 2,
            onExecute: {}
        )
        ActionRowView(
            item: ActionItem(
                name: "Downloads",
                type: .folder,
                path: "~/Downloads",
                isEnabled: false
            ),
            index: 3,
            onExecute: {}
        )
    }
    .padding()
    .frame(width: 280)
}
