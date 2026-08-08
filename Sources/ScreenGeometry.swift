import AppKit

enum ScreenGeometry {
    /// Convert a Cocoa-coordinate rect (origin bottom-left) to Accessibility coords (origin top-left of main display).
    static func toAccessibility(_ cocoaRect: CGRect) -> CGRect {
        guard let primary = NSScreen.screens.first else { return cocoaRect }
        return CGRect(
            x: cocoaRect.origin.x,
            y: primary.frame.maxY - cocoaRect.maxY,
            width: cocoaRect.width,
            height: cocoaRect.height
        )
    }

    /// Convert Accessibility coords to Cocoa.
    static func toCocoa(_ accessibilityRect: CGRect) -> CGRect {
        guard let primary = NSScreen.screens.first else { return accessibilityRect }
        return CGRect(
            x: accessibilityRect.origin.x,
            y: primary.frame.maxY - accessibilityRect.maxY,
            width: accessibilityRect.width,
            height: accessibilityRect.height
        )
    }

    static func accessibilityMouseLocation() -> CGPoint {
        let cocoa = NSEvent.mouseLocation
        guard let primary = NSScreen.screens.first else { return cocoa }
        return CGPoint(x: cocoa.x, y: primary.frame.maxY - cocoa.y)
    }

    static func screenContainingMouse() -> NSScreen? {
        let point = NSEvent.mouseLocation
        return NSScreen.screens.first { NSMouseInRect(point, $0.frame, false) } ?? NSScreen.main
    }
}
