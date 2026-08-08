import Foundation
import AppKit

final class Preferences {
    static let shared = Preferences()

    private let sizesKey = "snapSizes.v3"
    private let enabledKey = "snapEnabled"
    private let edgeThicknessKey = "edgeThickness"

    var sizes: SnapSizes {
        didSet { saveSizes() }
    }

    var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: enabledKey) }
    }

    /// Thickness of edge hot zones in points.
    var edgeThickness: CGFloat {
        didSet { UserDefaults.standard.set(Double(edgeThickness), forKey: edgeThicknessKey) }
    }

    private init() {
        if let data = UserDefaults.standard.data(forKey: sizesKey),
           let decoded = try? JSONDecoder().decode(SnapSizes.self, from: data) {
            sizes = decoded
        } else {
            sizes = .default
        }

        if UserDefaults.standard.object(forKey: enabledKey) == nil {
            isEnabled = true
        } else {
            isEnabled = UserDefaults.standard.bool(forKey: enabledKey)
        }

        let stored = UserDefaults.standard.double(forKey: edgeThicknessKey)
        edgeThickness = stored > 0 ? CGFloat(stored) : 28
    }

    private func saveSizes() {
        if let data = try? JSONEncoder().encode(sizes) {
            UserDefaults.standard.set(data, forKey: sizesKey)
        }
    }

    func resetSizes() {
        sizes = .default
    }
}
