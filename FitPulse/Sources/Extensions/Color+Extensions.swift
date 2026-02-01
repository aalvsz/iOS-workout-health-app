import SwiftUI

extension Color {
    // MARK: - App Theme Colors
    static let appPrimary = Color("AccentColor")
    static let appSecondary = Color.blue.opacity(0.8)
    static let appBackground = Color(uiColor: .systemBackground)
    static let appSecondaryBackground = Color(uiColor: .secondarySystemBackground)
    static let appTertiaryBackground = Color(uiColor: .tertiarySystemBackground)

    // MARK: - Recovery Colors
    static let recoveryOptimal = Color.green
    static let recoveryGood = Color.mint
    static let recoveryModerate = Color.yellow
    static let recoveryNeedsRest = Color.orange
    static let recoveryCritical = Color.red

    // MARK: - Activity Colors
    static let caloriesRing = Color.red
    static let exerciseRing = Color.green
    static let standRing = Color.cyan

    // MARK: - Macro Colors
    static let proteinColor = Color.blue
    static let carbsColor = Color.orange
    static let fatColor = Color.purple

    // MARK: - Workout Type Colors
    static let cardioColor = Color.red
    static let strengthColor = Color.purple
    static let flexibilityColor = Color.teal
    static let hiitColor = Color.orange

    // MARK: - Chart Colors
    static let chartPrimary = Color.blue
    static let chartSecondary = Color.green
    static let chartTertiary = Color.orange
    static let chartBackground = Color.gray.opacity(0.1)

    // MARK: - Status Colors
    static let success = Color.green
    static let warning = Color.yellow
    static let error = Color.red
    static let info = Color.blue

    // MARK: - Gradients
    static let primaryGradient = LinearGradient(
        colors: [Color.blue, Color.purple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let recoveryGradient = LinearGradient(
        colors: [Color.green, Color.cyan],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let energyGradient = LinearGradient(
        colors: [Color.orange, Color.red],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let sleepGradient = LinearGradient(
        colors: [Color.indigo, Color.purple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Recovery Status Colors
    static func recoveryColor(for status: RecoveryStatus) -> Color {
        switch status {
        case .optimal: return .recoveryOptimal
        case .good: return .recoveryGood
        case .moderate: return .recoveryModerate
        case .needsRest: return .recoveryNeedsRest
        case .critical: return .recoveryCritical
        }
    }

    // MARK: - Hex Initializer
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Gradient Extensions
extension LinearGradient {
    static let primaryGradient = LinearGradient(
        colors: [Color.blue, Color.purple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let recoveryGradient = LinearGradient(
        colors: [Color.green, Color.cyan],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let energyGradient = LinearGradient(
        colors: [Color.orange, Color.red],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let sleepGradient = LinearGradient(
        colors: [Color.indigo, Color.purple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func forRecoveryScore(_ score: Double) -> LinearGradient {
        let colors: [Color]
        switch score {
        case 85...:
            colors = [.green, .mint]
        case 70..<85:
            colors = [.mint, .cyan]
        case 55..<70:
            colors = [.yellow, .orange]
        case 40..<55:
            colors = [.orange, .red]
        default:
            colors = [.red, .pink]
        }

        return LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
    }
}
