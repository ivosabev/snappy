import AppKit

final class DragMonitor {
    private let overlay = OverlayController()
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var pollTimer: Timer?

    private var isDragging = false
    private var dragStartPoint: CGPoint?
    private var trackedWindow: AXUIElement?
    private var activeZone: SnapZone?

    private let dragThreshold: CGFloat = 6

    func start() {
        stop()

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .leftMouseDragged, .leftMouseUp]) { [weak self] event in
            DispatchQueue.main.async {
                self?.handle(event)
            }
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .leftMouseDragged, .leftMouseUp]) { [weak self] event in
            DispatchQueue.main.async {
                self?.handle(event)
            }
            return event
        }
    }

    func stop() {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
        pollTimer?.invalidate()
        pollTimer = nil
        resetDragState()
    }

    private func handle(_ event: NSEvent) {
        guard Preferences.shared.isEnabled else {
            resetDragState()
            return
        }
        guard AccessibilityService.isTrusted() else { return }

        switch event.type {
        case .leftMouseDown:
            beginPotentialDrag()
        case .leftMouseDragged:
            updateDrag()
        case .leftMouseUp:
            endDrag()
        default:
            break
        }
    }

    private func beginPotentialDrag() {
        dragStartPoint = NSEvent.mouseLocation
        trackedWindow = AccessibilityService.windowAtMouse()
        isDragging = false
        activeZone = nil
    }

    private func updateDrag() {
        guard let start = dragStartPoint else { return }
        let current = NSEvent.mouseLocation
        let distance = hypot(current.x - start.x, current.y - start.y)

        if !isDragging {
            guard distance >= dragThreshold else { return }
            isDragging = true
            if trackedWindow == nil {
                trackedWindow = AccessibilityService.windowAtMouse()
                    ?? AccessibilityService.focusedWindowOfFrontmostApp()
            }
        }

        guard trackedWindow != nil else {
            overlay.hide()
            activeZone = nil
            return
        }

        guard let screen = ScreenGeometry.screenContainingMouse() else { return }
        let thickness = Preferences.shared.edgeThickness
        let zone = SnapZone.allCases.first {
            $0.hotRect(in: screen.frame, thickness: thickness).contains(current)
        }

        if let zone {
            activeZone = zone
            overlay.show(zone: zone, screen: screen, sizes: Preferences.shared.sizes)
        } else {
            activeZone = nil
            overlay.hide()
        }
    }

    private func endDrag() {
        defer { resetDragState() }

        guard isDragging,
              let zone = activeZone,
              let window = trackedWindow,
              let screen = ScreenGeometry.screenContainingMouse() else {
            return
        }

        let cocoaFrame = zone.windowFrame(in: screen.visibleFrame, sizes: Preferences.shared.sizes)
        let axFrame = ScreenGeometry.toAccessibility(cocoaFrame)
        AccessibilityService.setFrame(axFrame, of: window)
    }

    private func resetDragState() {
        isDragging = false
        dragStartPoint = nil
        trackedWindow = nil
        activeZone = nil
        overlay.hide()
    }
}
