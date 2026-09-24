// Copyright 2026 Nick Fay
// SPDX-License-Identifier: Apache-2.0

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
