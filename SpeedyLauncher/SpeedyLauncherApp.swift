import SwiftUI

@main
struct SpeedyLauncherApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var storage = StorageService.shared

    var body: some Scene {
        Settings {
            SettingsView(storage: storage)
        }
    }
}
