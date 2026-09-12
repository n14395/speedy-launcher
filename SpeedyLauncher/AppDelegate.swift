import SwiftUI
import AppKit
import Combine

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var eventMonitor: Any?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupHotkey()
        setupEventMonitor()
        observeSettingsChanges()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            updateMenuBarIcon()
            button.action = #selector(togglePopover)
            button.target = self
        }

        popover = NSPopover()
        popover?.behavior = .transient
        popover?.animates = true
        popover?.delegate = self
        popover?.contentViewController = NSHostingController(
            rootView: MenuPopoverView(storage: StorageService.shared)
        )
    }

    private func observeSettingsChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMenuBarIconChanged),
            name: .menuBarIconChanged,
            object: nil
        )

        StorageService.shared.$settings
            .sink { settings in
                if settings.enableKeyboardShortcuts {
                    HotkeyManager.shared.registerGlobalHotkey(settings.globalHotkey)
                    HotkeyManager.shared.registerItemHotkeys(settings.items, menuHotkey: settings.globalHotkey)
                } else {
                    HotkeyManager.shared.unregisterGlobalHotkey()
                    HotkeyManager.shared.unregisterAllItemHotkeys()
                }
            }
            .store(in: &cancellables)
    }

    @objc private func handleMenuBarIconChanged() {
        updateMenuBarIcon()
    }

    private func updateMenuBarIcon() {
        if let button = statusItem?.button {
            let iconName = StorageService.shared.settings.menuBarIconName
            button.image = NSImage(systemSymbolName: iconName, accessibilityDescription: "Quick Actions")
        }
    }

    private func setupHotkey() {
        let settings = StorageService.shared.settings
        if settings.enableKeyboardShortcuts {
            HotkeyManager.shared.registerGlobalHotkey(settings.globalHotkey)
            HotkeyManager.shared.registerItemHotkeys(settings.items, menuHotkey: settings.globalHotkey)
        }

        HotkeyManager.shared.onGlobalHotkeyPressed = { [weak self] in
            self?.togglePopover()
        }

        HotkeyManager.shared.onItemHotkeyPressed = { itemID in
            guard let item = StorageService.shared.findItem(byID: itemID) else { return }
            Task {
                try? await ActionExecutor.shared.execute(item)
            }
        }
    }

    private func setupEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            if let popover = self?.popover, popover.isShown {
                popover.performClose(nil)
            }
        }
    }

    @objc func togglePopover() {
        guard let button = statusItem?.button, let popover = popover else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            NotificationCenter.default.post(name: .popoverWillOpen, object: nil)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            // Bring app and popover window to front and make it key
            NSApp.activate(ignoringOtherApps: true)
            popover.contentViewController?.view.window?.makeKeyAndOrderFront(nil)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    nonisolated func popoverWillClose(_ notification: Notification) {
        Task { @MainActor in
            NotificationCenter.default.post(name: .popoverWillClose, object: nil)
        }
    }
}
