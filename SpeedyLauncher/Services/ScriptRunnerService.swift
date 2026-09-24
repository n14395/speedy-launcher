// Copyright 2026 Nick Fay
// SPDX-License-Identifier: Apache-2.0

import Foundation
import AppKit

enum ScriptRunnerError: LocalizedError {
    case scriptsFolderUnavailable
    case runnerNotInstalled
    case installationCancelled
    case installationFailed(String)
    case runnerQuarantined(String)
    case toolFailed(String)

    var errorDescription: String? {
        switch self {
        case .scriptsFolderUnavailable:
            return String(localized: "Could not locate the app's scripts folder in ~/Library/Application Scripts.")
        case .runnerNotInstalled:
            return String(localized: "Script execution is not enabled yet. Edit this item in Settings and click “Enable Script Execution…”.")
        case .installationCancelled:
            return String(localized: "Script execution setup was cancelled.")
        case .installationFailed(let message):
            return String(localized: "Could not enable script execution: \(message)")
        case .runnerQuarantined(let path):
            return String(localized: """
            macOS quarantined the runner script, which would break the tools launched through it. \
            To fix this, run the following command in Terminal, then click “Enable Script Execution…” again:

            xattr -d com.apple.quarantine '\(path)'
            """)
        case .toolFailed(let message):
            return String(localized: "Command-line tool failed: \(message)")
        }
    }
}

/// Runs user-selected command-line tools with the user's full privileges from
/// inside the App Sandbox.
///
/// A sandboxed app cannot usefully spawn external binaries itself: child
/// processes inherit the static sandbox (without any Powerbox grants), so most
/// tools can't even be executed, let alone reach the user's files. Instead, a
/// small runner script installed in ~/Library/Application Scripts/<bundle-id>/
/// is executed via NSUserUnixTask, which runs scripts from that folder
/// *outside* the sandbox. The app can read that folder without any
/// entitlement, but writing the runner there requires a one-time explicit
/// user grant through an NSOpenPanel.
final class ScriptRunnerService: Sendable {
    static let shared = ScriptRunnerService()

    static let runnerScriptName = "run-tool.sh"

    static let runnerScriptContents = """
    #!/bin/sh
    # SpeedyLauncher tool runner.
    # Receives a tool path followed by its arguments and replaces itself with
    # that tool. NSUserUnixTask runs this script outside the app sandbox, so
    # the tool executes with the user's normal privileges.
    exec "$@"

    """

    private init() {}

    // MARK: - Scripts Folder

    var scriptsFolderURL: URL? {
        try? FileManager.default.url(
            for: .applicationScriptsDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )
    }

    var runnerURL: URL? {
        scriptsFolderURL?.appendingPathComponent(Self.runnerScriptName)
    }

    var isRunnerInstalled: Bool {
        guard let url = runnerURL else { return false }
        // A quarantined runner counts as not installed: executing through it
        // would taint the whole child process chain with the quarantine flag,
        // which spreads to files and app bundles those tools touch.
        return FileManager.default.isExecutableFile(atPath: url.path)
            && !Self.isFileQuarantined(atPath: url.path)
    }

    // MARK: - Quarantine Handling

    /// The sandbox stamps `com.apple.quarantine` on every file the app
    /// writes. Reading the xattr is always allowed, so this check works even
    /// where removal wouldn't.
    static func isFileQuarantined(atPath path: String) -> Bool {
        getxattr(path, "com.apple.quarantine", nil, 0, 0, 0) >= 0
    }

    /// Clears the quarantine attribute. `removexattr` is always denied in the
    /// sandbox; the resource-values API is the one route macOS permits, and
    /// only for executables covered by the
    /// `com.apple.security.files.user-selected.executable` entitlement.
    /// Callers must re-check `isFileQuarantined` afterwards — without that
    /// entitlement this call reports success but leaves the xattr in place.
    private static func removeQuarantine(from url: URL) throws {
        try (url as NSURL).setResourceValue(nil, forKey: .quarantinePropertiesKey)
    }

    // MARK: - Installation (requires user consent)

    /// Walks the user through granting write access to the scripts folder,
    /// then installs the runner script there. Must be called on the main
    /// thread because it presents an alert and an open panel.
    @MainActor
    func installRunnerWithConsent() throws {
        guard let folder = scriptsFolderURL else {
            throw ScriptRunnerError.scriptsFolderUnavailable
        }

        // The folder normally exists for sandboxed apps; creating it is
        // harmless where allowed and a silent no-op otherwise.
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        guard FileManager.default.fileExists(atPath: folder.path) else {
            throw ScriptRunnerError.installationFailed(
                String(localized: "The scripts folder does not exist. Please create it in Finder: \(folder.path)")
            )
        }

        let runnerFile = folder.appendingPathComponent(Self.runnerScriptName)

        // If a healthy, up-to-date runner is already in place (e.g. the user
        // just cleared the quarantine in Terminal), there is nothing to do.
        // Rewriting it would only re-quarantine it and undo their fix.
        if isRunnerInstalled,
           (try? String(contentsOf: runnerFile, encoding: .utf8)) == Self.runnerScriptContents {
            return
        }

        // If the runner is current but quarantined, try clearing in place
        // before asking for any permissions — succeeds if a grant from
        // earlier in this session is still active.
        if (try? String(contentsOf: runnerFile, encoding: .utf8)) == Self.runnerScriptContents,
           Self.isFileQuarantined(atPath: runnerFile.path) {
            try? Self.removeQuarantine(from: runnerFile)
            if isRunnerInstalled {
                return
            }
        }

        let alert = NSAlert()
        alert.messageText = String(localized: "Enable Script Execution")
        alert.informativeText = String(localized: """
        To run command-line tools, SpeedyLauncher installs a small runner script at:

        \(runnerFile.path)

        macOS asks for your permission. In the next dialog, simply click “Install” — don't change the name or location.
        """)
        alert.addButton(withTitle: String(localized: "Continue"))
        alert.addButton(withTitle: String(localized: "Cancel"))
        NSApp.activate(ignoringOtherApps: true)

        guard alert.runModal() == .alertFirstButtonReturn else {
            throw ScriptRunnerError.installationCancelled
        }

        // A save panel, not a folder grant: the entitlement that lets us
        // strip the quarantine from the written script
        // (com.apple.security.files.user-selected.executable) applies to
        // files the user selects directly, so the runner file itself must be
        // what the user chooses in the dialog.
        let panel = NSSavePanel()
        panel.directoryURL = folder
        panel.nameFieldStringValue = Self.runnerScriptName
        panel.canCreateDirectories = false
        panel.prompt = String(localized: "Install")
        panel.message = String(localized: "Click “Install” to place the runner script in this folder.")

        guard panel.runModal() == .OK, let savedURL = panel.url else {
            throw ScriptRunnerError.installationCancelled
        }

        // NSUserUnixTask only executes items in the scripts folder, and only
        // this exact file name is ever run, so any other destination is
        // useless.
        let savedPath = savedURL.standardizedFileURL.resolvingSymlinksInPath().path
        let expectedPath = runnerFile.standardizedFileURL.resolvingSymlinksInPath().path
        guard savedPath == expectedPath else {
            throw ScriptRunnerError.installationFailed(
                String(localized: "The runner must be saved as \(Self.runnerScriptName) in \(folder.path). Please try again without changing the name or location.")
            )
        }

        do {
            // Non-atomic write: the save-panel grant covers exactly this URL,
            // not the sibling temp file an atomic write would go through.
            try Self.runnerScriptContents.write(to: savedURL, atomically: false, encoding: .utf8)
            try FileManager.default.setAttributes(
                [.posixPermissions: 0o755],
                ofItemAtPath: savedURL.path
            )
            try Self.removeQuarantine(from: savedURL)
        } catch {
            throw ScriptRunnerError.installationFailed(error.localizedDescription)
        }

        // Verify rather than trust: the quarantine-clearing API reports
        // success even where the sandbox silently ignored it.
        if Self.isFileQuarantined(atPath: savedURL.path) {
            throw ScriptRunnerError.runnerQuarantined(savedURL.path)
        }
    }

    // MARK: - Execution

    /// Executes a command-line tool through the runner script, outside the
    /// sandbox. `toolPath` must be absolute (tilde already expanded).
    func run(toolPath: String, arguments: [String]) async throws {
        guard isRunnerInstalled, let runnerURL else {
            throw ScriptRunnerError.runnerNotInstalled
        }

        let task: NSUserUnixTask
        do {
            task = try NSUserUnixTask(url: runnerURL)
        } catch {
            throw ScriptRunnerError.toolFailed(error.localizedDescription)
        }

        let stderrPipe = Pipe()
        task.standardError = stderrPipe.fileHandleForWriting

        do {
            try await task.execute(withArguments: [toolPath] + arguments)
            try? stderrPipe.fileHandleForWriting.close()
        } catch {
            // NSUserUnixTask reports both launch failures and nonzero exit
            // statuses here; include whatever the tool wrote to stderr.
            try? stderrPipe.fileHandleForWriting.close()
            var message = error.localizedDescription
            if let data = try? stderrPipe.fileHandleForReading.readToEnd(),
               let output = String(data: data, encoding: .utf8)?
                   .trimmingCharacters(in: .whitespacesAndNewlines),
               !output.isEmpty {
                message += "\n" + output.suffix(500)
            }
            throw ScriptRunnerError.toolFailed(message)
        }
    }
}
