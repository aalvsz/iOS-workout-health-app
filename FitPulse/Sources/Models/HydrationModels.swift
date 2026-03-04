import Foundation

// MARK: - Hydration Entry
struct HydrationEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let amountMl: Int
    let source: HydrationSource

    init(id: UUID = UUID(), date: Date = Date(), amountMl: Int, source: HydrationSource = .water) {
        self.id = id
        self.date = date
        self.amountMl = amountMl
        self.source = source
    }

    var effectiveHydration: Int {
        Int(Double(amountMl) * source.hydrationFactor)
    }
}

// MARK: - Hydration Source
enum HydrationSource: String, Codable, CaseIterable {
    case water = "Water"
    case tea = "Tea"
    case coffee = "Coffee"
    case sportsDrink = "Sports Drink"
    case juice = "Juice"
    case other = "Other"

    var displayName: String {
        switch self {
        case .water: return String(localized: "Water")
        case .tea: return String(localized: "Tea")
        case .coffee: return String(localized: "Coffee")
        case .sportsDrink: return String(localized: "Sports Drink")
        case .juice: return String(localized: "Juice")
        case .other: return String(localized: "Other")
        }
    }

    var icon: String {
        switch self {
        case .water: return "drop.fill"
        case .tea: return "leaf.fill"
        case .coffee: return "cup.and.saucer.fill"
        case .sportsDrink: return "bolt.fill"
        case .juice: return "carrot.fill"
        case .other: return "waterbottle.fill"
        }
    }

    var hydrationFactor: Double {
        switch self {
        case .water: return 1.0
        case .tea: return 0.95
        case .coffee: return 0.8  // Slight diuretic effect
        case .sportsDrink: return 1.1  // Electrolytes help retention
        case .juice: return 0.9
        case .other: return 0.85
        }
    }

    var color: String {
        switch self {
        case .water: return "hydrationWater"
        case .tea: return "hydrationTea"
        case .coffee: return "hydrationCoffee"
        case .sportsDrink: return "hydrationSports"
        case .juice: return "hydrationJuice"
        case .other: return "hydrationOther"
        }
    }
}

// MARK: - Hydration Goal
struct HydrationGoal {
    let baseMl: Int
    let activityBonusMl: Int
    let weatherBonusMl: Int

    var totalMl: Int {
        baseMl + activityBonusMl + weatherBonusMl
    }

    var totalLiters: Double {
        Double(totalMl) / 1000.0
    }

    init(baseMl: Int, activityBonusMl: Int = 0, weatherBonusMl: Int = 0) {
        self.baseMl = baseMl
        self.activityBonusMl = activityBonusMl
        self.weatherBonusMl = weatherBonusMl
    }

    static func calculate(weightKg: Double, workoutMinutes: Double = 0) -> HydrationGoal {
        // Base: 35ml per kg bodyweight
        let base = Int(weightKg * 35)

        // Activity bonus: ~500ml per hour of workout
        let activityBonus = Int((workoutMinutes / 60.0) * 500)

        return HydrationGoal(baseMl: base, activityBonusMl: activityBonus)
    }
}

// MARK: - Hydration Status
enum HydrationStatus: String, CaseIterable {
    case dehydrated = "Dehydrated"
    case low = "Low"
    case adequate = "Adequate"
    case good = "Good"
    case excellent = "Excellent"

    var displayName: String {
        switch self {
        case .dehydrated: return String(localized: "Dehydrated")
        case .low: return String(localized: "Low")
        case .adequate: return String(localized: "Adequate")
        case .good: return String(localized: "Good")
        case .excellent: return String(localized: "Excellent")
        }
    }

    var icon: String {
        switch self {
        case .dehydrated: return "drop.triangle.fill"
        case .low: return "drop.fill"
        case .adequate: return "drop.halffull"
        case .good: return "drop.fill"
        case .excellent: return "drop.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .dehydrated: return "hydrationDehydrated"
        case .low: return "hydrationLow"
        case .adequate: return "hydrationAdequate"
        case .good: return "hydrationGood"
        case .excellent: return "hydrationExcellent"
        }
    }

    var message: String {
        switch self {
        case .dehydrated:
            return String(localized: "You need to drink more water! Dehydration affects performance and recovery.")
        case .low:
            return String(localized: "Your hydration is below target. Try to drink a glass of water soon.")
        case .adequate:
            return String(localized: "You're adequately hydrated. Keep it up!")
        case .good:
            return String(localized: "Good hydration! You're on track for the day.")
        case .excellent:
            return String(localized: "Excellent hydration! Your body will thank you.")
        }
    }

    static func from(progress: Double) -> HydrationStatus {
        switch progress {
        case ..<0.25: return .dehydrated
        case 0.25..<0.5: return .low
        case 0.5..<0.75: return .adequate
        case 0.75..<1.0: return .good
        default: return .excellent
        }
    }
}

// MARK: - Daily Hydration Summary
struct DailyHydrationSummary: Identifiable {
    let id: UUID
    let date: Date
    let entries: [HydrationEntry]
    let goal: HydrationGoal

    init(id: UUID = UUID(), date: Date, entries: [HydrationEntry], goal: HydrationGoal) {
        self.id = id
        self.date = date
        self.entries = entries
        self.goal = goal
    }

    var totalIntakeMl: Int {
        entries.reduce(0) { $0 + $1.amountMl }
    }

    var effectiveIntakeMl: Int {
        entries.reduce(0) { $0 + $1.effectiveHydration }
    }

    var progress: Double {
        guard goal.totalMl > 0 else { return 0 }
        return Double(totalIntakeMl) / Double(goal.totalMl)
    }

    var status: HydrationStatus {
        HydrationStatus.from(progress: progress)
    }

    var remainingMl: Int {
        max(0, goal.totalMl - totalIntakeMl)
    }

    var bySource: [HydrationSource: Int] {
        Dictionary(grouping: entries, by: { $0.source })
            .mapValues { entries in entries.reduce(0) { $0 + $1.amountMl } }
    }
}
