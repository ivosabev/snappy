import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var dragMonitor: DragMonitor!
    private var preferencesWindow: PreferencesWindowController?
    private var permissionTimer: Timer?
    private var wasTrusted = false
    private var didShowPermissionAlert = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        if let icon = NSImage(named: "AppIcon") {
            NSApp.applicationIconImage = icon
        } else if let url = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
                  let icon = NSImage(contentsOf: url) {
            NSApp.applicationIconImage = icon
        }
        dragMonitor = DragMonitor()
        setupStatusItem()
        ensureAccessibility()
        dragMonitor.start()

        permissionTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.pollPermission()
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        dragMonitor.stop()
        permissionTimer?.invalidate()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        refreshMenu()
    }

    private func pollPermission() {
        let trusted = AccessibilityService.isTrusted()
        if trusted && !wasTrusted {
            wasTrusted = true
            refreshMenu()
            return
        }
        if !trusted {
            wasTrusted = false
            refreshMenu()
        }
    }

    private func refreshMenu() {
        let menu = NSMenu()
        let trusted = AccessibilityService.isTrusted()
        wasTrusted = trusted

        if let button = statusItem.button {
            let symbol = trusted ? "rectangle.3.group" : "exclamationmark.triangle"
            button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: "Snappy")
            button.image?.isTemplate = true
            button.toolTip = trusted
                ? "Snappy — drag windows to screen edges"
                : "Snappy needs Accessibility permission"
        }

        if !trusted {
            let warning = NSMenuItem(
                title: "Needs Accessibility Permission",
                action: nil,
                keyEquivalent: ""
            )
            warning.isEnabled = false
            menu.addItem(warning)

            let grant = NSMenuItem(
                title: "Open Accessibility Settings…",
                action: #selector(requestAccessibility),
                keyEquivalent: ""
            )
            grant.target = self
            menu.addItem(grant)
            menu.addItem(.separator())
        }

        let enabledItem = NSMenuItem(
            title: Preferences.shared.isEnabled ? "Snapping: On" : "Snapping: Off",
            action: #selector(toggleEnabled),
            keyEquivalent: ""
        )
        enabledItem.target = self
        enabledItem.state = Preferences.shared.isEnabled ? .on : .off
        enabledItem.isEnabled = trusted
        menu.addItem(enabledItem)

        menu.addItem(.separator())

        let prefs = NSMenuItem(title: "Preferences…", action: #selector(openPreferences), keyEquivalent: ",")
        prefs.target = self
        menu.addItem(prefs)

        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Quit Snappy", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        statusItem.menu = menu
    }

    private func ensureAccessibility() {
        if AccessibilityService.isTrusted(prompt: true) {
            wasTrusted = true
            return
        }

        AccessibilityService.openAccessibilitySettings()

        guard !didShowPermissionAlert else { return }
        didShowPermissionAlert = true

        let alert = NSAlert()
        alert.messageText = "Enable Snappy in Accessibility"
        alert.informativeText = """
        macOS blocks window resizing until Snappy is allowed.

        1. System Settings → Privacy & Security → Accessibility
        2. Remove any old SnapZones / Snappy entries
        3. Add /Applications/Snappy.app and turn it ON

        Use ./build.sh so the app is signed with a stable identity and installed to /Applications — then rebuilds keep this permission.
        """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "OK")
        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            AccessibilityService.openAccessibilitySettings()
        }
    }

    @objc private func toggleEnabled() {
        Preferences.shared.isEnabled.toggle()
        refreshMenu()
    }

    @objc private func openPreferences() {
        if preferencesWindow == nil {
            preferencesWindow = PreferencesWindowController()
        }
        preferencesWindow?.show()
    }

    @objc private func requestAccessibility() {
        _ = AccessibilityService.isTrusted(prompt: true)
        AccessibilityService.openAccessibilitySettings()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
