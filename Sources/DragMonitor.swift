import AppKit

final class DragMonitor {
    private let overlay = OverlayController()
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var pollTimer: Timer?

    private var isDragging = false
    private var dragStartPoint: CGPoint?
    private var dragStartFrame: CGRect?
    private var trackedWindow: AXUIElement?
    private var activeZone: SnapZone?

    /// Mouse must move at least this far before we consider a drag.
    private let dragThreshold: CGFloat = 6
    /// Window origin must move at least this far before snap zones activate.
    /// Filters out scrollbar drags, text selection, and other in-window gestures.
    private let windowMoveThreshold: CGFloat = 4

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
        isDragging = false
        activeZone = nil
        dragStartFrame = nil
        trackedWindow = nil

        // Scrollbars and similar controls produce left-drags without moving the window.
        guard !AccessibilityService.isNonWindowDragControlAtMouse() else {
            dragStartPoint = nil
            return
        }

        dragStartPoint = NSEvent.mouseLocation
        trackedWindow = AccessibilityService.windowAtMouse()
        if let trackedWindow {
            dragStartFrame = AccessibilityService.frame(of: trackedWindow)
        }
    }

    private func updateDrag() {
        guard let start = dragStartPoint else { return }
        let current = NSEvent.mouseLocation
        let distance = hypot(current.x - start.x, current.y - start.y)

        if !isDragging {
            guard distance >= dragThreshold else { return }

            if trackedWindow == nil {
                trackedWindow = AccessibilityService.windowAtMouse()
            }
            guard let window = trackedWindow else { return }

            if dragStartFrame == nil {
                dragStartFrame = AccessibilityService.frame(of: window)
            }
            // Only treat this as a window drag once the window itself has moved.
            guard let startFrame = dragStartFrame,
                  let currentFrame = AccessibilityService.frame(of: window) else {
                return
            }
            let originDistance = hypot(
                currentFrame.origin.x - startFrame.origin.x,
                currentFrame.origin.y - startFrame.origin.y
            )
            guard originDistance >= windowMoveThreshold else { return }

            isDragging = true
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
        dragStartFrame = nil
        trackedWindow = nil
        activeZone = nil
        overlay.hide()
    }
}
