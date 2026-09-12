import SwiftUI

/// Shared "Script Execution" status/setup form section, used by the item
/// editor (for command-line tool items) and the General settings tab.
struct ScriptExecutionSection: View {
    /// How many command-line tool actions depend on the runner. When script
    /// execution is not set up, a nonzero count makes the warning concrete.
    var dependentToolCount: Int = 0

    @State private var runnerInstalled: Bool = ScriptRunnerService.shared.isRunnerInstalled
    @State private var runnerError: String?

    var body: some View {
        Section("Script Execution") {
            if runnerInstalled {
                Label("Script execution is enabled.", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)

                Text("Tools run with your normal user permissions via the runner script in the app's scripts folder.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Label(notSetUpWarning, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)

                Text("Command-line tools run outside the App Sandbox through a small runner script. Enabling this requires a one-time permission to install the script.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button("Enable Script Execution…") {
                    enableScriptExecution()
                }

                if let runnerError {
                    Label(runnerError, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
        .onAppear {
            runnerInstalled = ScriptRunnerService.shared.isRunnerInstalled
        }
    }

    private var notSetUpWarning: String {
        switch dependentToolCount {
        case 0:
            return String(localized: "Script execution is not set up.")
        case 1:
            return String(localized: "Script execution is not set up — your command-line tool action won't run.")
        default:
            return String(localized: "Script execution is not set up — your \(dependentToolCount) command-line tool actions won't run.")
        }
    }

    private func enableScriptExecution() {
        do {
            try ScriptRunnerService.shared.installRunnerWithConsent()
            runnerError = nil
        } catch ScriptRunnerError.installationCancelled {
            // User backed out; nothing to report.
        } catch {
            runnerError = error.localizedDescription
        }
        runnerInstalled = ScriptRunnerService.shared.isRunnerInstalled
    }
}

#Preview {
    Form {
        ScriptExecutionSection(dependentToolCount: 2)
    }
    .formStyle(.grouped)
}
