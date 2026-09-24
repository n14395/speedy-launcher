// Copyright 2026 Nick Fay
// SPDX-License-Identifier: Apache-2.0

import SwiftUI

struct CategoryHeaderView: View {
    let category: ActionItem
    let index: Int
    var showIndex: Bool = true
    let onToggle: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 8) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(category.isExpanded ? 90 : 0))
                    .animation(.easeInOut(duration: 0.2), value: category.isExpanded)

                Image(systemName: category.effectiveIcon)
                    .font(.system(size: 12))

                Text(category.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)

                Spacer()

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
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .focusEffectDisabled()
        .background(isHovering ? Color.secondary.opacity(0.1) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

#Preview {
    VStack(spacing: 4) {
        CategoryHeaderView(
            category: ActionItem(
                name: "Development",
                type: .category,
                icon: "hammer.fill",
                children: [
                    ActionItem(name: "Test", type: .app, path: ""),
                    ActionItem(name: "Test 2", type: .app, path: "")
                ],
                isExpanded: true
            ),
            index: 1,
            onToggle: {}
        )
        CategoryHeaderView(
            category: ActionItem(
                name: "Utilities",
                type: .category,
                icon: "wrench.fill",
                children: [
                    ActionItem(name: "Test", type: .app, path: "")
                ],
                isExpanded: false
            ),
            index: 2,
            onToggle: {}
        )
    }
    .padding()
    .frame(width: 280)
}
