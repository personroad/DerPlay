import Foundation

/// CarLife only: plan the source raster from the receiver's reported viewport.
/// The wire negotiation still advertises the actual source dimensions.
enum DerPlayCarLifeDisplay {
    // The wire report contains dimensions, not a trustworthy orientation or viewport.
    // Default preserves compatibility with receivers reporting natural portrait dimensions.
    enum Direction: Int {
        case automatic = 0, reported, landscape, portrait

        func reference(width: Int, height: Int) -> (width: Int, height: Int) {
            switch self {
            case .reported: return (width, height)
            case .portrait: return (min(width, height), max(width, height))
            case .automatic, .landscape: return (max(width, height), min(width, height))
            }
        }
    }

    static func accepts(width: Int, height: Int) -> Bool {
        (320...16384).contains(width) && (320...16384).contains(height)
            && Double(max(width, height)) / Double(min(width, height)) <= 6
    }

    static func size(width: Int, height: Int, area: Int, direction: Direction = .automatic) -> (width: Int, height: Int)? {
        guard accepts(width: width, height: height), area > 0 else { return nil }
        let reference = direction.reference(width: width, height: height)
        let aspect = Double(reference.width) / Double(reference.height)
        // Keep existing decoder limits; do not inflate a short edge or distort the aspect.
        let maxHeight = min(Double(reference.height), 1080, 1920 / aspect,
                            (Double(area) / aspect).squareRoot())
        let h = Int(maxHeight / 2) * 2
        let w = Int(Double(h) * aspect / 2) * 2
        guard h >= 320, w >= 320, w <= 1920, h <= 1080 else { return nil }
        return (w, h)
    }

    /// Fixed screen preference, constrained by the selected pixel budget and decoder limits.
    /// Return nil if both edges cannot meet CarPlay's minimum without exceeding the budget.
    static func fixedProfileSize(ratioWidth: Int, ratioHeight: Int, area: Int) -> (width: Int, height: Int)? {
        guard ratioWidth > 0, ratioHeight > 0, area > 0 else { return nil }
        let aspect = Double(ratioWidth) / Double(ratioHeight)
        let maxHeight = min(1080.0, 1920 / aspect, (Double(area) / aspect).squareRoot())
        let h = Int(maxHeight / 2) * 2
        let w = Int(Double(h) * aspect / 2) * 2
        guard (320...1920).contains(w), (320...1080).contains(h), w * h <= area else { return nil }
        return (w, h)
    }

    /// Single startup raster. A new report cannot change an already advertised source.
    struct Negotiation {
        let area: Int
        let direction: Direction
        private(set) var raster: (width: Int, height: Int)?

        init(area: Int, direction: Direction = .automatic) { self.area = area; self.direction = direction }

        func selection(width: Int, height: Int) -> (width: Int, height: Int)? {
            raster ?? DerPlayCarLifeDisplay.size(width: width, height: height, area: area, direction: direction)
        }

        /// Called only after queuing the encoder reply. Only the first success starts CarPlay.
        mutating func commit(width: Int, height: Int) -> Bool {
            guard raster == nil else { return false }
            raster = (width, height)
            return true
        }
    }

    static func needsAdaptation(width: Int, height: Int, liveWidth: Int, liveHeight: Int, direction: Direction = .automatic) -> Bool {
        guard width > 0, height > 0, liveWidth > 0, liveHeight > 0 else { return false }
        let reference = direction.reference(width: width, height: height)
        return abs(Double(reference.width) * Double(liveHeight) / (Double(reference.height) * Double(liveWidth)) - 1) > 0.015
    }
}
