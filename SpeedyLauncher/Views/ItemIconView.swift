// Copyright 2026 Nick Fay
// SPDX-License-Identifier: Apache-2.0

import SwiftUI
import AppKit

struct ItemIconView: View {
    let item: ActionItem
    let size: CGFloat

    var body: some View {
        Group {
            if item.icon != nil && !item.icon!.isEmpty {
                // Custom SF Symbol icon specified
                Image(systemName: item.effectiveIcon)
                    .font(.system(size: size * 0.7))
            } else if item.type == .app || item.type == .folder {
                // Use filesystem icon for apps and folders
                filesystemIcon
            } else {
                // Use SF Symbol for other types
                Image(systemName: item.effectiveIcon)
                    .font(.system(size: size * 0.7))
            }
        }
        .frame(width: size, height: size)
    }

    @ViewBuilder
    private var filesystemIcon: some View {
        let expandedPath = NSString(string: item.path).expandingTildeInPath
        let nsImage = NSWorkspace.shared.icon(forFile: expandedPath)
        Image(nsImage: nsImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
}

#Preview {
    VStack(spacing: 10) {
        ItemIconView(
            item: ActionItem(name: "Safari", type: .app, path: "/Applications/Safari.app"),
            size: 32
        )
        ItemIconView(
            item: ActionItem(name: "Downloads", type: .folder, path: "~/Downloads"),
            size: 32
        )
        ItemIconView(
            item: ActionItem(name: "Shortcut", type: .shortcut, path: "My Shortcut"),
            size: 32
        )
        ItemIconView(
            item: ActionItem(name: "Custom", type: .app, path: "/Applications/Safari.app", icon: "star.fill"),
            size: 32
        )
    }
    .padding()
}
