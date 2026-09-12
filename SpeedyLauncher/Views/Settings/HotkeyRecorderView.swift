import SwiftUI
import AppKit

struct HotkeyRecorderView: View {
    @Binding var config: KeyboardShortcutConfig?
    @State private var isRecording = false
    @State private var eventMonitor: Any?

    var body: some View {
        HStack {
            Button {
                startRecording()
            } label: {
                Text(displayText)
                    .font(.system(.body, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .frame(minWidth: 80)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isRecording ? AnyShapeStyle(Color.accentColor.opacity(0.2)) : AnyShapeStyle(.quaternary))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isRecording ? Color.accentColor : Color.clear, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            if config != nil && !isRecording {
                Button("Clear") {
                    config = nil
                }
            }

            if isRecording {
                Button("Cancel") {
                    stopRecording()
                }
            }
        }
        .onDisappear {
            stopRecording()
        }
    }

    private var displayText: String {
        if isRecording {
            return "Press shortcut..."
        }
        return config?.displayString ?? "Not Set"
    }

    private func startRecording() {
        guard !isRecording else { return }
        isRecording = true

        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 { // Escape key
                stopRecording()
                return nil
            }

            if let newConfig = HotkeyManager.configFromEvent(event) {
                config = newConfig
                stopRecording()
                return nil
            }

            return nil
        }
    }

    private func stopRecording() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        isRecording = false
    }
}
