import AppKit

final class OverlayController {
    private var overlayWindow: NSWindow?
    private var highlightView: SnapHighlightView?

    func show(zone: SnapZone, screen: NSScreen, sizes: SnapSizes) {
        let frame = zone.windowFrame(in: screen.visibleFrame, sizes: sizes)

        if overlayWindow == nil {
            let window = NSWindow(
                contentRect: frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            window.isOpaque = false
            window.backgroundColor = .clear
            window.level = .floating
            window.ignoresMouseEvents = true
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            window.hasShadow = false

            let view = SnapHighlightView(frame: NSRect(origin: .zero, size: frame.size))
            window.contentView = view
            highlightView = view
            overlayWindow = window
        }

        overlayWindow?.setFrame(frame, display: true)
        highlightView?.frame = NSRect(origin: .zero, size: frame.size)
        highlightView?.label = zone.displayName
        highlightView?.needsDisplay = true
        overlayWindow?.orderFront(nil)
    }

    func hide() {
        overlayWindow?.orderOut(nil)
    }
}

final class SnapHighlightView: NSView {
    var label: String = ""

    override func draw(_ dirtyRect: NSRect) {
        let bounds = self.bounds.insetBy(dx: 6, dy: 6)
        let path = NSBezierPath(roundedRect: bounds, xRadius: 12, yRadius: 12)

        NSColor.systemBlue.withAlphaComponent(0.22).setFill()
        path.fill()

        NSColor.systemBlue.withAlphaComponent(0.85).setStroke()
        path.lineWidth = 3
        path.stroke()

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 18, weight: .semibold),
            .foregroundColor: NSColor.white,
            .paragraphStyle: paragraph
        ]

        let textSize = (label as NSString).size(withAttributes: attributes)
        let textRect = CGRect(
            x: (bounds.width - textSize.width) / 2 + bounds.minX,
            y: (bounds.height - textSize.height) / 2 + bounds.minY,
            width: textSize.width,
            height: textSize.height
        )

        // Soft label backdrop
        let badge = textRect.insetBy(dx: -14, dy: -8)
        let badgePath = NSBezierPath(roundedRect: badge, xRadius: 8, yRadius: 8)
        NSColor.black.withAlphaComponent(0.35).setFill()
        badgePath.fill()

        (label as NSString).draw(in: textRect, withAttributes: attributes)
    }
}
