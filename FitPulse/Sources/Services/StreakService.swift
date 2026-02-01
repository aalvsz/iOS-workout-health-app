import Foundation

class StreakService {
    static let shared = StreakService()

    private let persistence = PersistenceController.shared
    private let hydrationService = HydrationService.shared

    private init() {}

    // MARK: - Streak Initialization

    func initializeStreaksIfNeeded() {
        var streaks = persistence.loadStreaks()

        // Create default streaks for each type if they don't exist
        for type in StreakType.allCases {
            if !streaks.contains(where: { $0.type == type }) {
                let streak = Streak(type: type)
                streaks.append(streak)
            }
        }

        persistence.saveStreaks(streaks)
    }

    // MARK: - Get Streaks

    func getAllStreaks() -> [Streak] {
        var streaks = persistence.loadStreaks()

        // Check and reset broken streaks
        for i in 0..<streaks.count {
            streaks[i].checkAndResetIfBroken()
        }

        persistence.saveStreaks(streaks)
        return streaks
    }

    func getStreak(for type: StreakType) -> Streak {
        if let streak = persistence.getStreak(for: type) {
            var mutableStreak = streak
            mutableStreak.checkAndResetIfBroken()
            persistence.updateStreak(mutableStreak)
            return mutableStreak
        }

        // Create new streak if it doesn't exist
        let newStreak = Streak(type: type)
        persistence.updateStreak(newStreak)
        return newStreak
    }

    func getActiveStreaks() -> [Streak] {
        getAllStreaks().filter { $0.currentCount > 0 && $0.isActive }
    }

    func getLongestStreak() -> Streak? {
        getAllStreaks().max { $0.longestCount < $1.longestCount }
    }

    func getStreakAtRisk() -> Streak? {
        getAllStreaks().first { $0.isAtRisk && $0.currentCount > 0 }
    }

    // MARK: - Record Activity

    func recordWorkoutActivity() {
        var streak = getStreak(for: .workout)
        streak.recordActivity()
        persistence.updateStreak(streak)

        // Also update overall streak
        checkAndUpdateOverallStreak()
    }

    func recordLoggingActivity() {
        var streak = getStreak(for: .logging)
        streak.recordActivity()
        persistence.updateStreak(streak)

        checkAndUpdateOverallStreak()
    }

    func recordHydrationGoalMet() {
        var streak = getStreak(for: .hydration)
        streak.recordActivity()
        persistence.updateStreak(streak)

        checkAndUpdateOverallStreak()
    }

    func recordStepGoalMet() {
        var streak = getStreak(for: .steps)
        streak.recordActivity()
        persistence.updateStreak(streak)

        checkAndUpdateOverallStreak()
    }

    // MARK: - Check Activity

    func checkWorkoutActivity(workoutCount: Int) {
        if workoutCount > 0 {
            recordWorkoutActivity()
        }
    }

    func checkHydrationGoal(profile: UserProfile, todayActivity: DailyHealthSummary?) {
        let goal = hydrationService.calculateDailyGoal(profile: profile, todayActivity: todayActivity)
        let intake = hydrationService.getTodayIntake()

        if intake >= goal.totalMl {
            recordHydrationGoalMet()
        }
    }

    func checkStepGoal(steps: Int, goal: Int = 10000) {
        if steps >= goal {
            recordStepGoalMet()
        }
    }

    func checkLoggingActivity(mealsLogged: Int, weightLogged: Bool) {
        if mealsLogged > 0 || weightLogged {
            recordLoggingActivity()
        }
    }

    // MARK: - Overall Streak

    private func checkAndUpdateOverallStreak() {
        // Overall streak is active if at least 3 of 4 activity types were done today
        let streaks = getAllStreaks().filter { $0.type != .overall }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let activeToday = streaks.filter { streak in
            calendar.isDate(streak.lastActivityDate, inSameDayAs: today)
        }.count

        if activeToday >= 3 {
            var overallStreak = getStreak(for: .overall)
            overallStreak.recordActivity()
            persistence.updateStreak(overallStreak)
        }
    }

    // MARK: - Streak Milestones

    func getStreakMilestone(for count: Int) -> String? {
        switch count {
        case 3: return "3-Day Starter"
        case 7: return "Week Warrior"
        case 14: return "Two-Week Champion"
        case 21: return "Habit Former"
        case 30: return "Monthly Master"
        case 50: return "Dedication Star"
        case 100: return "Century Legend"
        case 365: return "Year-Round Champion"
        default: return nil
        }
    }

    func getNextMilestone(from current: Int) -> Int {
        let milestones = [3, 7, 14, 21, 30, 50, 100, 365]
        return milestones.first { $0 > current } ?? current + 1
    }

    // MARK: - Streak Summary

    func getStreakSummary() -> StreakSummary {
        let streaks = getAllStreaks()
        let activeStreaks = streaks.filter { $0.currentCount > 0 && $0.isActive }
        let longestCurrent = streaks.max { $0.currentCount < $1.currentCount }
        let allTimeBest = streaks.max { $0.longestCount < $1.longestCount }
        let atRisk = streaks.first { $0.isAtRisk && $0.currentCount > 0 }

        return StreakSummary(
            totalActiveStreaks: activeStreaks.count,
            longestCurrentStreak: longestCurrent,
            allTimeBestStreak: allTimeBest,
            streakAtRisk: atRisk,
            streaks: streaks
        )
    }
}

// MARK: - Streak Summary Model

struct StreakSummary {
    let totalActiveStreaks: Int
    let longestCurrentStreak: Streak?
    let allTimeBestStreak: Streak?
    let streakAtRisk: Streak?
    let streaks: [Streak]

    var hasAnyStreak: Bool {
        totalActiveStreaks > 0
    }

    var bestCurrentCount: Int {
        longestCurrentStreak?.currentCount ?? 0
    }

    var bestAllTimeCount: Int {
        allTimeBestStreak?.longestCount ?? 0
    }
}
