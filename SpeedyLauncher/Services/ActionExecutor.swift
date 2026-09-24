// Copyright 2026 Nick Fay
// SPDX-License-Identifier: Apache-2.0

import Foundation
import AppKit

enum ActionError: LocalizedError {
    case appNotFound(String)
    case shortcutFailed(String)
    case folderNotFound(String)
    case folderAccessDenied(String)
    case unknownError(String)

    var errorDescription: String? {
        switch self {
        case .appNotFound(let path):
            return "Application not found: \(path)"
        case .shortcutFailed(let message):
            return "Shortcut execution failed: \(message)"
        case .folderNotFound(let path):
            return "Folder not found: \(path)"
        case .folderAccessDenied(let path):
            return "Access denied to folder: \(path). Please re-select the folder in Settings."
        case .unknownError(let message):
            return "Unknown error: \(message)"
        }
    }
}

actor ActionExecutor {
    static let shared = ActionExecutor()

    private init() {}

    func execute(_ item: ActionItem) async throws {
        guard item.isEnabled else { return }

        switch item.type {
        case .app:
            try await openApp(at: item.path, arguments: item.launchArguments)
        case .shortcut:
            try await runShortcut(named: item.path)
        case .folder:
            try await openFolder(item)
        case .category:
            return
        }
    }

    // MARK: - App Launching

    private func openApp(at path: String, arguments: String? = nil) async throws {
        let expandedPath = NSString(string: path).expandingTildeInPath
        let url = URL(fileURLWithPath: expandedPath)

        guard FileManager.default.fileExists(atPath: expandedPath) else {
            throw ActionError.appNotFound(path)
        }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true

        let parsedArguments = Self.parseArguments(arguments ?? "")
        if !parsedArguments.isEmpty {
            configuration.arguments = parsedArguments
            // Arguments only reach a process at spawn, so an already-running app
            // would just be activated and the arguments silently dropped
            configuration.createsNewApplicationInstance = true
        }

        do {
            try await NSWorkspace.shared.openApplication(at: url, configuration: configuration)
        } catch {
            throw ActionError.unknownError(error.localizedDescription)
        }
    }

    /// Splits a command-line string into arguments, honoring single quotes,
    /// double quotes, and backslash escapes (outside single quotes).
    static func parseArguments(_ string: String) -> [String] {
        var arguments: [String] = []
        var current = ""
        var hasToken = false
        var inSingleQuotes = false
        var inDoubleQuotes = false
        var isEscaped = false

        for character in string {
            if isEscaped {
                current.append(character)
                isEscaped = false
                continue
            }

            switch character {
            case "\\" where !inSingleQuotes:
                isEscaped = true
                hasToken = true
            case "'" where !inDoubleQuotes:
                inSingleQuotes.toggle()
                hasToken = true
            case "\"" where !inSingleQuotes:
                inDoubleQuotes.toggle()
                hasToken = true
            case " ", "\t":
                if inSingleQuotes || inDoubleQuotes {
                    current.append(character)
                } else if hasToken {
                    arguments.append(current)
                    current = ""
                    hasToken = false
                }
            default:
                current.append(character)
                hasToken = true
            }
        }

        if hasToken {
            arguments.append(current)
        }

        return arguments
    }

    // MARK: - Shortcuts Execution

    private func runShortcut(named name: String) async throws {
        // Use shortcuts:// URL scheme instead of CLI for sandbox compatibility
        guard let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "shortcuts://run-shortcut?name=\(encodedName)") else {
            throw ActionError.shortcutFailed("Invalid shortcut name: \(name)")
        }

        let opened = await MainActor.run {
            NSWorkspace.shared.open(url)
        }

        if !opened {
            throw ActionError.shortcutFailed("Could not open Shortcuts app for: \(name)")
        }
    }

    // MARK: - Folder Opening

    private func openFolder(_ item: ActionItem) async throws {
        // Try to use security-scoped bookmark if available
        if let bookmarkData = item.bookmarkData {
            do {
                var isStale = false
                let url = try URL(
                    resolvingBookmarkData: bookmarkData,
                    options: .withSecurityScope,
                    relativeTo: nil,
                    bookmarkDataIsStale: &isStale
                )

                if url.startAccessingSecurityScopedResource() {
                    defer { url.stopAccessingSecurityScopedResource() }

                    _ = await MainActor.run {
                        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: url.path)
                    }
                    return
                }
            } catch {
                // Bookmark failed, fall through to try path-based access
            }
        }

        // Fallback to path-based access (works for user-selected locations)
        let expandedPath = NSString(string: item.path).expandingTildeInPath

        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: expandedPath, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            throw ActionError.folderNotFound(item.path)
        }

        _ = await MainActor.run {
            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: expandedPath)
        }
    }
}
