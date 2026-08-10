import AppKit
import ApplicationServices

enum AccessibilityService {
    static func isTrusted(prompt: Bool = false) -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    static func openAccessibilitySettings() {
        let candidates = [
            "x-apple.systemsettings:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility",
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        ]
        for candidate in candidates {
            if let url = URL(string: candidate), NSWorkspace.shared.open(url) {
                return
            }
        }
    }

    /// Frontmost window under the cursor that is not our own process.
    static func windowAtMouse() -> AXUIElement? {
        guard let element = elementAtMouse() else { return nil }

        var current: AXUIElement? = element
        while let candidate = current {
            if role(of: candidate) == (kAXWindowRole as String) {
                if isOwnWindow(candidate) { return nil }
                return candidate
            }

            var parent: CFTypeRef?
            if AXUIElementCopyAttributeValue(candidate, kAXParentAttribute as CFString, &parent) != .success {
                break
            }
            current = (parent as! AXUIElement)
        }

        return focusedWindowOfFrontmostApp()
    }

    /// True when the press started on a control that commonly produces left-drags
    /// without moving the window (scrollbars, sliders, etc.).
    static func isNonWindowDragControlAtMouse() -> Bool {
        guard let element = elementAtMouse() else { return false }

        let ignoredRoles: Set<String> = [
            kAXScrollBarRole as String,
            kAXSliderRole as String,
            kAXIncrementorRole as String,
            kAXHandleRole as String,
            "AXSplitter",
        ]

        var current: AXUIElement? = element
        while let candidate = current {
            if let role = role(of: candidate) {
                if role == (kAXWindowRole as String) { return false }
                if ignoredRoles.contains(role) { return true }
            }

            var parent: CFTypeRef?
            if AXUIElementCopyAttributeValue(candidate, kAXParentAttribute as CFString, &parent) != .success {
                break
            }
            current = (parent as! AXUIElement)
        }

        return false
    }

    static func focusedWindowOfFrontmostApp() -> AXUIElement? {
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        if app.processIdentifier == ProcessInfo.processInfo.processIdentifier { return nil }

        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        var window: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &window) == .success,
              let window else {
            return nil
        }
        return (window as! AXUIElement)
    }

    static func frame(of window: AXUIElement) -> CGRect? {
        var positionValue: CFTypeRef?
        var sizeValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionValue) == .success,
              AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeValue) == .success,
              let positionValue, let sizeValue else {
            return nil
        }

        var position = CGPoint.zero
        var size = CGSize.zero
        guard AXValueGetValue(positionValue as! AXValue, .cgPoint, &position),
              AXValueGetValue(sizeValue as! AXValue, .cgSize, &size) else {
            return nil
        }

        return CGRect(origin: position, size: size)
    }

    static func setFrame(_ frame: CGRect, of window: AXUIElement) {
        var position = frame.origin
        var size = frame.size

        if let positionValue = AXValueCreate(.cgPoint, &position) {
            AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, positionValue)
        }
        if let sizeValue = AXValueCreate(.cgSize, &size) {
            AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
        }
        // Some apps need position again after size.
        if let positionValue = AXValueCreate(.cgPoint, &position) {
            AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, positionValue)
        }
    }

    private static func elementAtMouse() -> AXUIElement? {
        let location = ScreenGeometry.accessibilityMouseLocation()
        let system = AXUIElementCreateSystemWide()

        var element: AXUIElement?
        let error = AXUIElementCopyElementAtPosition(
            system,
            Float(location.x),
            Float(location.y),
            &element
        )

        guard error == .success else { return nil }
        return element
    }

    private static func role(of element: AXUIElement) -> String? {
        var roleValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleValue) == .success else {
            return nil
        }
        return roleValue as? String
    }

    private static func isOwnWindow(_ window: AXUIElement) -> Bool {
        var pid: pid_t = 0
        AXUIElementGetPid(window, &pid)
        return pid == ProcessInfo.processInfo.processIdentifier
    }
}
