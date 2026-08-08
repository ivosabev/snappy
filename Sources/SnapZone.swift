import Foundation
import CoreGraphics

enum SnapZone: CaseIterable, Codable, Hashable {
    case topLeft
    case topCenter
    case topRight
    case leftCenter
    case rightCenter
    case bottomLeft
    case bottomCenter
    case bottomRight

    var displayName: String {
        switch self {
        case .topLeft: "Top Left"
        case .topCenter: "Top Center"
        case .topRight: "Top Right"
        case .leftCenter: "Left Center"
        case .rightCenter: "Right Center"
        case .bottomLeft: "Bottom Left"
        case .bottomCenter: "Center"
        case .bottomRight: "Bottom Right"
        }
    }

    /// Hot zone on screen where releasing the mouse triggers this snap.
    func hotRect(in screenFrame: CGRect, thickness: CGFloat) -> CGRect {
        let w = screenFrame.width
        let h = screenFrame.height
        let x = screenFrame.minX
        let y = screenFrame.minY
        let corner = min(w, h) * 0.22
        let edge = thickness

        switch self {
        case .topLeft:
            return CGRect(x: x, y: y + h - corner, width: corner, height: corner)
        case .topCenter:
            return CGRect(x: x + corner, y: y + h - edge, width: w - 2 * corner, height: edge)
        case .topRight:
            return CGRect(x: x + w - corner, y: y + h - corner, width: corner, height: corner)
        case .leftCenter:
            return CGRect(x: x, y: y + corner, width: edge, height: h - 2 * corner)
        case .rightCenter:
            return CGRect(x: x + w - edge, y: y + corner, width: edge, height: h - 2 * corner)
        case .bottomLeft:
            return CGRect(x: x, y: y, width: corner, height: corner)
        case .bottomCenter:
            return CGRect(x: x + corner, y: y, width: w - 2 * corner, height: edge)
        case .bottomRight:
            return CGRect(x: x + w - corner, y: y, width: corner, height: corner)
        }
    }

    /// Preview / final window frame as fractions of the visible screen.
    func windowFrame(in visibleFrame: CGRect, sizes: SnapSizes) -> CGRect {
        let size = sizes.size(for: self)
        let width = visibleFrame.width * size.widthFraction
        let height = visibleFrame.height * size.heightFraction

        let originX: CGFloat
        switch self {
        case .topLeft, .leftCenter, .bottomLeft:
            originX = visibleFrame.minX
        case .topCenter, .bottomCenter:
            originX = visibleFrame.midX - width / 2
        case .topRight, .rightCenter, .bottomRight:
            originX = visibleFrame.maxX - width
        }

        let originY: CGFloat
        switch self {
        case .topLeft, .topRight:
            originY = visibleFrame.maxY - height
        case .topCenter:
            // Full-screen maximize sits on the visible frame origin.
            originY = visibleFrame.minY + (visibleFrame.height - height) / 2
        case .leftCenter, .rightCenter, .bottomCenter:
            originY = visibleFrame.midY - height / 2
        case .bottomLeft, .bottomRight:
            originY = visibleFrame.minY
        }

        return CGRect(x: originX, y: originY, width: width, height: height)
    }
}

struct ZoneSize: Codable, Equatable {
    /// Fraction of screen width (0...1)
    var widthFraction: CGFloat
    /// Fraction of screen height (0...1)
    var heightFraction: CGFloat
}

struct SnapSizes: Codable, Equatable {
    var topLeft: ZoneSize
    var topCenter: ZoneSize
    var topRight: ZoneSize
    var leftCenter: ZoneSize
    var rightCenter: ZoneSize
    var bottomLeft: ZoneSize
    var bottomCenter: ZoneSize
    var bottomRight: ZoneSize

    static let `default` = SnapSizes(
        topLeft: ZoneSize(widthFraction: 0.66, heightFraction: 0.5),
        topCenter: ZoneSize(widthFraction: 1.0, heightFraction: 1.0),
        topRight: ZoneSize(widthFraction: 0.34, heightFraction: 0.5),
        leftCenter: ZoneSize(widthFraction: 0.66, heightFraction: 1.0),
        rightCenter: ZoneSize(widthFraction: 0.34, heightFraction: 1.0),
        bottomLeft: ZoneSize(widthFraction: 0.66, heightFraction: 0.5),
        bottomCenter: ZoneSize(widthFraction: 1.0, heightFraction: 1.0),
        bottomRight: ZoneSize(widthFraction: 0.34, heightFraction: 0.5)
    )

    func size(for zone: SnapZone) -> ZoneSize {
        switch zone {
        case .topLeft: topLeft
        case .topCenter: topCenter
        case .topRight: topRight
        case .leftCenter: leftCenter
        case .rightCenter: rightCenter
        case .bottomLeft: bottomLeft
        case .bottomCenter: bottomCenter
        case .bottomRight: bottomRight
        }
    }

    mutating func set(_ size: ZoneSize, for zone: SnapZone) {
        switch zone {
        case .topLeft: topLeft = size
        case .topCenter: topCenter = size
        case .topRight: topRight = size
        case .leftCenter: leftCenter = size
        case .rightCenter: rightCenter = size
        case .bottomLeft: bottomLeft = size
        case .bottomCenter: bottomCenter = size
        case .bottomRight: bottomRight = size
        }
    }
}
