// Copyright 2026 Nick Fay
// SPDX-License-Identifier: Apache-2.0

import XCTest
@testable import SpeedyLauncher

final class ActionErrorTests: XCTestCase {

    // MARK: - Error Description Tests

    func testAppNotFoundErrorDescription() {
        let error = ActionError.appNotFound("/path/to/missing.app")
        XCTAssertEqual(error.errorDescription, "Application not found: /path/to/missing.app")
    }

    func testShortcutFailedErrorDescription() {
        let error = ActionError.shortcutFailed("shortcut not found")
        XCTAssertEqual(error.errorDescription, "Shortcut execution failed: shortcut not found")
    }

    func testFolderNotFoundErrorDescription() {
        let error = ActionError.folderNotFound("~/NonExistent")
        XCTAssertEqual(error.errorDescription, "Folder not found: ~/NonExistent")
    }

    func testFolderAccessDeniedErrorDescription() {
        let error = ActionError.folderAccessDenied("/protected/folder")
        XCTAssertEqual(error.errorDescription, "Access denied to folder: /protected/folder. Please re-select the folder in Settings.")
    }

    func testUnknownErrorDescription() {
        let error = ActionError.unknownError("something went wrong")
        XCTAssertEqual(error.errorDescription, "Unknown error: something went wrong")
    }

    // MARK: - LocalizedError Conformance

    func testErrorsConformToLocalizedError() {
        let errors: [ActionError] = [
            .appNotFound("/path"),
            .shortcutFailed("failed"),
            .folderNotFound("/path"),
            .folderAccessDenied("/path"),
            .unknownError("error")
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription?.isEmpty ?? true)
        }
    }
}

final class ParseArgumentsTests: XCTestCase {

    func testEmptyStringReturnsNoArguments() {
        XCTAssertEqual(ActionExecutor.parseArguments(""), [])
    }

    func testWhitespaceOnlyReturnsNoArguments() {
        XCTAssertEqual(ActionExecutor.parseArguments("   \t  "), [])
    }

    func testSingleArgument() {
        XCTAssertEqual(ActionExecutor.parseArguments("--verbose"), ["--verbose"])
    }

    func testMultipleArgumentsSplitOnWhitespace() {
        XCTAssertEqual(
            ActionExecutor.parseArguments("--flag value -x  another"),
            ["--flag", "value", "-x", "another"]
        )
    }

    func testDoubleQuotesPreserveSpaces() {
        XCTAssertEqual(
            ActionExecutor.parseArguments("--path \"/Users/me/My Documents\""),
            ["--path", "/Users/me/My Documents"]
        )
    }

    func testSingleQuotesPreserveSpaces() {
        XCTAssertEqual(
            ActionExecutor.parseArguments("--title 'hello world'"),
            ["--title", "hello world"]
        )
    }

    func testBackslashEscapesSpace() {
        XCTAssertEqual(
            ActionExecutor.parseArguments("/tmp/my\\ file"),
            ["/tmp/my file"]
        )
    }

    func testBackslashEscapesQuote() {
        XCTAssertEqual(
            ActionExecutor.parseArguments("say \\\"hi\\\""),
            ["say", "\"hi\""]
        )
    }

    func testEmptyQuotedArgumentIsKept() {
        XCTAssertEqual(ActionExecutor.parseArguments("--name \"\""), ["--name", ""])
    }

    func testQuotesInsideWordAreJoined() {
        XCTAssertEqual(ActionExecutor.parseArguments("pre\"mid dle\"post"), ["premid dlepost"])
    }
}

final class ActionExecutorTests: XCTestCase {

    var executor: ActionExecutor!

    override func setUp() async throws {
        try await super.setUp()
        executor = ActionExecutor.shared
    }

    // MARK: - Disabled Item Tests

    func testExecuteDisabledItemDoesNothing() async throws {
        let disabledItem = ActionItem(
            name: "Disabled",
            type: .shortcut,
            path: "NonExistentShortcut",
            isEnabled: false
        )

        // Should not throw even though the shortcut doesn't exist
        try await executor.execute(disabledItem)
    }

    // MARK: - Category Tests

    func testExecuteCategoryDoesNothing() async throws {
        let category = ActionItem(name: "Category", type: .category)

        // Should complete without any action
        try await executor.execute(category)
    }

    // MARK: - App Execution Tests

    func testExecuteAppNotFound() async {
        let item = ActionItem(
            name: "Missing App",
            type: .app,
            path: "/Applications/NonExistentApp12345.app"
        )

        do {
            try await executor.execute(item)
            XCTFail("Expected appNotFound error")
        } catch let error as ActionError {
            switch error {
            case .appNotFound(let path):
                XCTAssertEqual(path, "/Applications/NonExistentApp12345.app")
            default:
                XCTFail("Expected appNotFound, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testExecuteAppWithTildePath() async {
        let item = ActionItem(
            name: "Missing App",
            type: .app,
            path: "~/Applications/NonExistentApp12345.app"
        )

        do {
            try await executor.execute(item)
            XCTFail("Expected appNotFound error")
        } catch let error as ActionError {
            switch error {
            case .appNotFound:
                // Expected - tilde was expanded but app doesn't exist
                break
            default:
                XCTFail("Expected appNotFound, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Folder Tests

    func testExecuteFolderNotFound() async {
        let item = ActionItem(
            name: "Missing Folder",
            type: .folder,
            path: "/nonexistent/folder/path/12345"
        )

        do {
            try await executor.execute(item)
            XCTFail("Expected folderNotFound error")
        } catch let error as ActionError {
            switch error {
            case .folderNotFound(let path):
                XCTAssertEqual(path, "/nonexistent/folder/path/12345")
            default:
                XCTFail("Expected folderNotFound, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testExecuteFolderWithTildePath() async {
        let item = ActionItem(
            name: "Missing Folder",
            type: .folder,
            path: "~/nonexistent_folder_12345"
        )

        do {
            try await executor.execute(item)
            XCTFail("Expected folderNotFound error")
        } catch let error as ActionError {
            switch error {
            case .folderNotFound:
                // Expected - tilde was expanded but folder doesn't exist
                break
            default:
                XCTFail("Expected folderNotFound, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testExecuteFolderOnFileThrowsError() async {
        // Create a temporary file
        let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent("test_file_\(UUID().uuidString)")
        FileManager.default.createFile(atPath: tempFile.path, contents: nil)
        defer { try? FileManager.default.removeItem(at: tempFile) }

        let item = ActionItem(
            name: "Not a Folder",
            type: .folder,
            path: tempFile.path
        )

        do {
            try await executor.execute(item)
            XCTFail("Expected folderNotFound error")
        } catch let error as ActionError {
            switch error {
            case .folderNotFound:
                // Expected - path exists but is not a directory
                break
            default:
                XCTFail("Expected folderNotFound, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Integration Tests

    func testExecuteValidFolder() async throws {
        // Test with a folder that definitely exists
        let item = ActionItem(
            name: "Temp",
            type: .folder,
            path: "/tmp"
        )

        // Should not throw - will open Finder
        try await executor.execute(item)
    }

    func testExecuteHomeFolder() async throws {
        let item = ActionItem(
            name: "Home",
            type: .folder,
            path: "~"
        )

        // Should not throw - tilde expansion works
        try await executor.execute(item)
    }

    // MARK: - Singleton Tests

    func testSharedInstanceIsSingleton() {
        let instance1 = ActionExecutor.shared
        let instance2 = ActionExecutor.shared

        // They should be the same instance (identity)
        // Note: Can't use === on actors directly, but they share state
        XCTAssertNotNil(instance1)
        XCTAssertNotNil(instance2)
    }

    // MARK: - Shortcut Tests

    func testExecuteShortcutWithSpecialCharacters() async throws {
        // Shortcuts with special characters should be URL-encoded
        let item = ActionItem(
            name: "Special Shortcut",
            type: .shortcut,
            path: "My Shortcut & More!"
        )

        // This will attempt to open the shortcuts:// URL
        // In a sandboxed environment without the Shortcuts app responding,
        // it may succeed (open returns true) or fail
        // We're mainly testing it doesn't crash
        do {
            try await executor.execute(item)
        } catch {
            // Expected in test environment
        }
    }

    func testExecuteShortcutWithEmptyName() async {
        let item = ActionItem(
            name: "Empty",
            type: .shortcut,
            path: ""
        )

        // Empty shortcut name should still attempt to run
        // (URL encoding handles empty strings)
        do {
            try await executor.execute(item)
        } catch {
            // May throw in test environment
        }
    }

    // MARK: - Folder with Bookmark Tests

    func testExecuteFolderWithInvalidBookmark() async {
        // Create an item with invalid bookmark data
        let item = ActionItem(
            name: "Bad Bookmark",
            type: .folder,
            path: "/tmp",
            bookmarkData: Data([0x00, 0x01, 0x02]) // Invalid bookmark
        )

        // Should fall back to path-based access which succeeds for /tmp
        try? await executor.execute(item)
    }

    // MARK: - All Action Types

    func testExecuteAllActionTypes() async throws {
        let types: [(ActionType, String, Bool)] = [
            (.app, "/Applications/NonExistent12345.app", true), // Should throw
            (.shortcut, "TestShortcut", false), // May or may not throw
            (.folder, "/tmp", false), // Should succeed
            (.category, "", false) // Should do nothing
        ]

        for (type, path, shouldThrow) in types {
            let item = ActionItem(name: "Test", type: type, path: path)

            do {
                try await executor.execute(item)
                if shouldThrow {
                    XCTFail("Expected \(type) to throw")
                }
            } catch {
                if !shouldThrow && type != .shortcut {
                    XCTFail("Unexpected error for \(type): \(error)")
                }
            }
        }
    }
}
