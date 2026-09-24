// Copyright 2026 Nick Fay
// SPDX-License-Identifier: Apache-2.0

import XCTest
@testable import SpeedyLauncher

final class ScriptRunnerServiceTests: XCTestCase {

    // MARK: - Runner Script Tests

    func testRunnerScriptStartsWithShellShebang() {
        XCTAssertTrue(ScriptRunnerService.runnerScriptContents.hasPrefix("#!/bin/sh\n"))
    }

    func testRunnerScriptExecsItsArguments() {
        XCTAssertTrue(ScriptRunnerService.runnerScriptContents.contains("exec \"$@\""))
    }

    func testRunnerScriptEndsWithNewline() {
        XCTAssertTrue(ScriptRunnerService.runnerScriptContents.hasSuffix("\n"))
    }

    func testRunnerScriptNameIsShellScript() {
        XCTAssertEqual(ScriptRunnerService.runnerScriptName, "run-tool.sh")
    }

    // MARK: - URL Tests

    func testRunnerURLAppendsScriptNameToScriptsFolder() throws {
        let service = ScriptRunnerService.shared
        guard let runnerURL = service.runnerURL,
              let folderURL = service.scriptsFolderURL else {
            throw XCTSkip("Application Scripts folder unavailable in this test environment")
        }

        XCTAssertEqual(runnerURL.lastPathComponent, ScriptRunnerService.runnerScriptName)
        XCTAssertEqual(runnerURL.deletingLastPathComponent().path, folderURL.path)
        XCTAssertTrue(folderURL.path.contains("Application Scripts"))
    }

    // MARK: - Error Description Tests

    func testAllErrorsHaveDescriptions() {
        let errors: [ScriptRunnerError] = [
            .scriptsFolderUnavailable,
            .runnerNotInstalled,
            .installationCancelled,
            .installationFailed("write failed"),
            .runnerQuarantined("/tmp/run-tool.sh"),
            .toolFailed("exit 1")
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription?.isEmpty ?? true)
        }
    }

    func testToolFailedIncludesMessage() {
        let error = ScriptRunnerError.toolFailed("No such file or directory")
        XCTAssertTrue(error.errorDescription?.contains("No such file or directory") ?? false)
    }

    func testInstallationFailedIncludesMessage() {
        let error = ScriptRunnerError.installationFailed("permission denied")
        XCTAssertTrue(error.errorDescription?.contains("permission denied") ?? false)
    }

    func testRunnerQuarantinedIncludesFixCommand() {
        let error = ScriptRunnerError.runnerQuarantined("/tmp/run-tool.sh")
        let description = error.errorDescription ?? ""
        XCTAssertTrue(description.contains("xattr -d com.apple.quarantine '/tmp/run-tool.sh'"))
    }

    // MARK: - Quarantine Detection Tests

    func testIsFileQuarantinedDetectsQuarantineAttribute() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("quarantine-test-\(UUID().uuidString).sh")
        try "#!/bin/sh\n".write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }

        if !ScriptRunnerService.isFileQuarantined(atPath: url.path) {
            // The environment didn't auto-quarantine the file on write, so add
            // the attribute through the quarantine-properties API — raw
            // setxattr of com.apple.quarantine is denied in the sandbox, but
            // marking a file as quarantined this way is always permitted.
            try (url as NSURL).setResourceValue(
                [kLSQuarantineTypeKey as String: kLSQuarantineTypeOtherDownload as String],
                forKey: .quarantinePropertiesKey
            )
        }

        XCTAssertTrue(ScriptRunnerService.isFileQuarantined(atPath: url.path))
    }

    func testIsFileQuarantinedFalseForMissingFile() {
        XCTAssertFalse(ScriptRunnerService.isFileQuarantined(atPath: "/nonexistent/path/tool"))
    }
}
