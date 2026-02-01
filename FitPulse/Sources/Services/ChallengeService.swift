import Foundation

class ChallengeService {
    static let shared = ChallengeService()

    private let persistence = PersistenceController.shared
    private let achievementService = AchievementService.shared

    private init() {}

    // MARK: - Challenge Templates

    static let challengeTemplates: [(title: String, description: String, type: ChallengeType, target: Int)] = [
        // Workout challenges
        ("Workout Week", "Complete 5 workouts this week", .workout, 5),
        ("Active Week", "Complete 7 workouts this week", .workout, 7),
        ("Double Down", "Complete 10 workouts this week", .workout, 10),

        // Steps challenges
        ("Step It Up", "Walk 50,000 steps this week", .steps, 50000),
        ("Marathon Week", "Walk 100,000 steps this week", .steps, 100000),
        ("Steps Champion", "Walk 150,000 steps this week", .steps, 150000),

        // Calorie challenges
        ("Calorie Crusher", "Burn 3,000 active calories this week", .calories, 3000),
        ("Fire Week", "Burn 5,000 active calories this week", .calories, 5000),
        ("Inferno", "Burn 7,000 active calories this week", .calories, 7000),

        // Hydration challenges
        ("Hydration Hero", "Meet your hydration goal 5 days this week", .hydration, 5),
        ("Perfect Hydration", "Meet your hydration goal every day this week", .hydration, 7),

        // Logging challenges
        ("Food Journal", "Log meals for 5 days this week", .logging, 5),
        ("Perfect Tracker", "Log meals every day this week", .logging, 7)
    ]

    // MARK: - Generate Weekly Challenge

    func generateWeeklyChallenge(profile: UserProfile) -> Challenge {
        // Select a random template appropriate for the user
        let template = selectAppropriateTemplate(for: profile)

        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek)!

        return Challenge(
            title: template.title,
            description: template.description,
            type: template.type,
            target: template.target,
            startDate: startOfWeek,
            endDate: endOfWeek
        )
    }

    private func selectAppropriateTemplate(for profile: UserProfile) -> (title: String, description: String, type: ChallengeType, target: Int) {
        // Filter templates based on user's workout goal
        var availableTemplates = Self.challengeTemplates

        // For users with lower workout goals, prefer easier challenges
        if profile.weeklyWorkoutGoal <= 3 {
            availableTemplates = availableTemplates.filter { template in
                switch template.type {
                case .workout:
                    return template.target <= 5
                case .steps:
                    return template.target <= 70000
                case .calories:
                    return template.target <= 4000
                default:
                    return true
                }
            }
        }

        // Get completed challenge types to add variety
        let completedTypes = Set(persistence.loadCompletedChallenges().suffix(3).map { $0.type })

        // Prefer types not recently completed
        let preferredTemplates = availableTemplates.filter { !completedTypes.contains($0.type) }

        if !preferredTemplates.isEmpty {
            return preferredTemplates.randomElement()!
        }

        return availableTemplates.randomElement() ?? Self.challengeTemplates[0]
    }

    // MARK: - Active Challenge

    func getActiveChallenge() -> Challenge? {
        persistence.getActiveChallenge()
    }

    func hasActiveChallenge() -> Bool {
        getActiveChallenge() != nil
    }

    func startChallenge(_ challenge: Challenge) {
        var newChallenge = challenge
        newChallenge.progress = 0
        persistence.saveChallenge(newChallenge)
    }

    func joinWeeklyChallenge(profile: UserProfile) -> Challenge {
        let challenge = generateWeeklyChallenge(profile: profile)
        startChallenge(challenge)
        return challenge
    }

    // MARK: - Update Progress

    func updateChallengeProgress() {
        guard var challenge = getActiveChallenge() else { return }

        let newProgress = calculateProgress(for: challenge)
        let wasCompleted = challenge.isCompleted

        challenge.updateProgress(newProgress)

        if !wasCompleted && challenge.isCompleted {
            // Challenge just completed
            handleChallengeCompletion(challenge)
        }

        persistence.saveChallenge(challenge)
    }

    private func calculateProgress(for challenge: Challenge) -> Int {
        switch challenge.type {
        case .workout:
            // Count workouts since challenge start
            return countWorkoutsSince(challenge.startDate)

        case .steps:
            // Sum steps since challenge start
            return sumStepsSince(challenge.startDate)

        case .calories:
            // Sum active calories since challenge start
            return sumActiveCaloriesSince(challenge.startDate)

        case .hydration:
            // Count days hydration goal was met
            return countHydrationGoalDaysSince(challenge.startDate)

        case .logging:
            // Count days with logged meals
            return countLoggingDaysSince(challenge.startDate)
        }
    }

    private func countWorkoutsSince(_ date: Date) -> Int {
        let summaries = persistence.loadCachedSummaries()
        return summaries.filter { $0.date >= date && $0.workoutCount > 0 }.count
    }

    private func sumStepsSince(_ date: Date) -> Int {
        let summaries = persistence.loadCachedSummaries()
        return summaries.filter { $0.date >= date }.reduce(0) { $0 + $1.steps }
    }

    private func sumActiveCaloriesSince(_ date: Date) -> Int {
        let summaries = persistence.loadCachedSummaries()
        return Int(summaries.filter { $0.date >= date }.reduce(0) { $0 + $1.activeCalories })
    }

    private func countHydrationGoalDaysSince(_ date: Date) -> Int {
        let entries = persistence.loadHydrationEntriesForWeek()
        let calendar = Calendar.current

        let groupedByDay = Dictionary(grouping: entries) { entry in
            calendar.startOfDay(for: entry.date)
        }

        // Assume goal is 2500ml
        return groupedByDay.values.filter { dayEntries in
            let total = dayEntries.reduce(0) { $0 + $1.amountMl }
            return total >= 2500
        }.count
    }

    private func countLoggingDaysSince(_ date: Date) -> Int {
        let meals = persistence.loadMealsForWeek()
        let calendar = Calendar.current

        let uniqueDays = Set(meals.filter { $0.date >= date }.map { calendar.startOfDay(for: $0.date) })
        return uniqueDays.count
    }

    // MARK: - Challenge Completion

    private func handleChallengeCompletion(_ challenge: Challenge) {
        // Update achievement progress
        let completedCount = persistence.loadCompletedChallenges().count + 1
        achievementService.updateChallengeProgress(completedChallenges: completedCount)

        // Send notification
        NotificationService.shared.sendChallengeCompleteNotification(challenge)

        // Post notification for UI update
        NotificationCenter.default.post(name: .challengeCompleted, object: challenge)
    }

    // MARK: - Challenge History

    func getCompletedChallenges() -> [Challenge] {
        persistence.loadCompletedChallenges()
    }

    func getChallengeStats() -> ChallengeStats {
        let completed = getCompletedChallenges()
        let active = getActiveChallenge()

        let completionsByType = Dictionary(grouping: completed) { $0.type }
            .mapValues { $0.count }

        return ChallengeStats(
            totalCompleted: completed.count,
            activeChallenge: active,
            completionsByType: completionsByType,
            currentStreak: calculateChallengeStreak(from: completed)
        )
    }

    private func calculateChallengeStreak(from completed: [Challenge]) -> Int {
        let sorted = completed.sorted { $0.completedDate ?? Date.distantPast > $1.completedDate ?? Date.distantPast }
        var streak = 0
        var expectedWeekStart = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!

        for challenge in sorted {
            guard let completedDate = challenge.completedDate else { continue }
            let challengeWeekStart = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: completedDate))!

            if Calendar.current.isDate(challengeWeekStart, equalTo: expectedWeekStart, toGranularity: .weekOfYear) {
                streak += 1
                expectedWeekStart = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: expectedWeekStart)!
            } else {
                break
            }
        }

        return streak
    }

    // MARK: - Abandon Challenge

    func abandonChallenge() {
        guard let challenge = getActiveChallenge() else { return }
        persistence.deleteChallenge(challenge)
    }
}

// MARK: - Challenge Stats

struct ChallengeStats {
    let totalCompleted: Int
    let activeChallenge: Challenge?
    let completionsByType: [ChallengeType: Int]
    let currentStreak: Int

    var hasActive: Bool {
        activeChallenge != nil
    }

    var mostCompletedType: ChallengeType? {
        completionsByType.max { $0.value < $1.value }?.key
    }
}

// MARK: - Notification Name

extension Notification.Name {
    static let challengeCompleted = Notification.Name("challengeCompleted")
}
