import Foundation

extension Double {
    // MARK: - Formatting
    var formatted0: String {
        String(format: "%.0f", self)
    }

    var formatted1: String {
        String(format: "%.1f", self)
    }

    var formatted2: String {
        String(format: "%.2f", self)
    }

    var formattedCalories: String {
        "\(Int(self)) kcal"
    }

    var formattedKm: String {
        String(format: "%.2f km", self)
    }

    var formattedSteps: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: Int(self))) ?? "\(Int(self))"
    }

    var formattedHours: String {
        let hours = Int(self)
        let minutes = Int((self - Double(hours)) * 60)
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    var formattedMinutes: String {
        let totalMinutes = Int(self)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes) min"
    }

    var formattedWeight: String {
        String(format: "%.1f kg", self)
    }

    var formattedPercentage: String {
        String(format: "%.0f%%", self * 100)
    }

    var formattedHRV: String {
        String(format: "%.0f ms", self)
    }

    var formattedHeartRate: String {
        String(format: "%.0f bpm", self)
    }

    // MARK: - Compact Formatting
    var compact: String {
        switch self {
        case 0..<1000:
            return "\(Int(self))"
        case 1000..<10000:
            return String(format: "%.1fK", self / 1000)
        case 10000..<1000000:
            return String(format: "%.0fK", self / 1000)
        default:
            return String(format: "%.1fM", self / 1000000)
        }
    }

    // MARK: - Delta Formatting
    func formattedDelta(showPlus: Bool = true) -> String {
        let prefix = self > 0 && showPlus ? "+" : ""
        return "\(prefix)\(formatted1)"
    }

    func formattedDeltaPercentage(showPlus: Bool = true) -> String {
        let prefix = self > 0 && showPlus ? "+" : ""
        return "\(prefix)\(String(format: "%.1f", self * 100))%"
    }

    // MARK: - Trend Arrow
    var trendArrow: String {
        switch self {
        case let x where x > 0.05:
            return "arrow.up"
        case let x where x < -0.05:
            return "arrow.down"
        default:
            return "arrow.right"
        }
    }

    // MARK: - Range Clamping
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }

    // MARK: - Progress
    func progress(in range: ClosedRange<Double>) -> Double {
        guard range.upperBound > range.lowerBound else { return 0 }
        return ((self - range.lowerBound) / (range.upperBound - range.lowerBound)).clamped(to: 0...1)
    }
}

extension Int {
    var formattedSteps: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }

    var formattedCalories: String {
        "\(self) kcal"
    }

    var formattedMinutes: String {
        let hours = self / 60
        let minutes = self % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes) min"
    }

    var compact: String {
        Double(self).compact
    }
}
