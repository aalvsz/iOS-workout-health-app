import Foundation

class HydrationService {
    static let shared = HydrationService()

    private let persistence = PersistenceController.shared

    private init() {}

    // MARK: - Daily Goal Calculation

    func calculateDailyGoal(profile: UserProfile, todayActivity: DailyHealthSummary?) -> HydrationGoal {
        let workoutMinutes = todayActivity?.workoutMinutes ?? 0
        return HydrationGoal.calculate(weightKg: profile.weightKg, workoutMinutes: workoutMinutes)
    }

    // MARK: - Intake Tracking

    func getTodayIntake() -> Int {
        let entries = persistence.loadHydrationEntries(for: Date())
        return entries.reduce(0) { $0 + $1.amountMl }
    }

    func getTodayEffectiveIntake() -> Int {
        let entries = persistence.loadHydrationEntries(for: Date())
        return entries.reduce(0) { $0 + $1.effectiveHydration }
    }

    func getTodayEntries() -> [HydrationEntry] {
        persistence.loadHydrationEntries(for: Date())
    }

    func getWeekEntries() -> [HydrationEntry] {
        persistence.loadHydrationEntriesForWeek()
    }

    // MARK: - Logging

    func logWater(amountMl: Int, source: HydrationSource = .water) {
        let entry = HydrationEntry(amountMl: amountMl, source: source)
        persistence.saveHydrationEntry(entry)
    }

    func logGlass(source: HydrationSource = .water) {
        logWater(amountMl: 250, source: source)
    }

    func logBottle(source: HydrationSource = .water) {
        logWater(amountMl: 500, source: source)
    }

    func deleteEntry(_ entry: HydrationEntry) {
        persistence.deleteHydrationEntry(entry)
    }

    // MARK: - Hydration Status

    func getHydrationStatus(profile: UserProfile, todayActivity: DailyHealthSummary?) -> HydrationStatus {
        let goal = calculateDailyGoal(profile: profile, todayActivity: todayActivity)
        let intake = getTodayIntake()

        guard goal.totalMl > 0 else { return .adequate }

        let progress = Double(intake) / Double(goal.totalMl)
        return HydrationStatus.from(progress: progress)
    }

    // MARK: - Daily Summary

    func getTodaySummary(profile: UserProfile, todayActivity: DailyHealthSummary?) -> DailyHydrationSummary {
        let entries = getTodayEntries()
        let goal = calculateDailyGoal(profile: profile, todayActivity: todayActivity)

        return DailyHydrationSummary(
            date: Date(),
            entries: entries,
            goal: goal
        )
    }

    // MARK: - Weekly Analysis

    func getWeeklyProgress(profile: UserProfile) -> [(date: Date, intake: Int, goal: Int)] {
        let calendar = Calendar.current
        let today = Date()
        var results: [(date: Date, intake: Int, goal: Int)] = []

        for dayOffset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }

            let entries = persistence.loadHydrationEntries(for: date)
            let intake = entries.reduce(0) { $0 + $1.amountMl }
            let goal = HydrationGoal.calculate(weightKg: profile.weightKg).totalMl

            results.append((date: date, intake: intake, goal: goal))
        }

        return results
    }

    // MARK: - Tips

    func getHydrationTip(status: HydrationStatus, remainingMl: Int) -> String {
        switch status {
        case .dehydrated:
            return "Drink \(remainingMl)ml more to reach your goal. Start with a full glass now!"
        case .low:
            return "You're behind on hydration. Try to drink \(min(remainingMl, 500))ml in the next hour."
        case .adequate:
            return "Keep up the good work! \(remainingMl)ml left to reach your target."
        case .good:
            return "Almost there! Just \(remainingMl)ml more to hit your goal."
        case .excellent:
            return "Great job staying hydrated! Keep sipping throughout the day."
        }
    }
}
