import Foundation

class AchievementService {
    static let shared = AchievementService()

    private let persistence = PersistenceController.shared
    private let streakService = StreakService.shared

    private init() {}

    // MARK: - Achievement Definitions

    static let allAchievementDefinitions: [Achievement] = [
        // Streak achievements
        Achievement(
            id: "streak_3_day",
            title: "Getting Started",
            description: "Complete a 3-day streak",
            tier: .bronze,
            category: .streak,
            targetValue: 3,
            iconName: "flame.fill"
        ),
        Achievement(
            id: "streak_7_day",
            title: "Week Warrior",
            description: "Complete a 7-day streak",
            tier: .silver,
            category: .streak,
            targetValue: 7,
            iconName: "flame.fill"
        ),
        Achievement(
            id: "streak_30_day",
            title: "Monthly Master",
            description: "Complete a 30-day streak",
            tier: .gold,
            category: .streak,
            targetValue: 30,
            iconName: "flame.fill"
        ),
        Achievement(
            id: "streak_100_day",
            title: "Century Legend",
            description: "Complete a 100-day streak",
            tier: .platinum,
            category: .streak,
            targetValue: 100,
            iconName: "crown.fill"
        ),

        // Workout achievements
        Achievement(
            id: "workout_first",
            title: "First Steps",
            description: "Complete your first workout",
            tier: .bronze,
            category: .workout,
            targetValue: 1,
            iconName: "figure.run"
        ),
        Achievement(
            id: "workout_10",
            title: "Getting Stronger",
            description: "Complete 10 workouts",
            tier: .bronze,
            category: .workout,
            targetValue: 10,
            iconName: "figure.run"
        ),
        Achievement(
            id: "workout_50",
            title: "Workout Warrior",
            description: "Complete 50 workouts",
            tier: .silver,
            category: .workout,
            targetValue: 50,
            iconName: "figure.strengthtraining.traditional"
        ),
        Achievement(
            id: "workout_100",
            title: "Fitness Fanatic",
            description: "Complete 100 workouts",
            tier: .gold,
            category: .workout,
            targetValue: 100,
            iconName: "figure.highintensity.intervaltraining"
        ),
        Achievement(
            id: "workout_500",
            title: "Elite Athlete",
            description: "Complete 500 workouts",
            tier: .platinum,
            category: .workout,
            targetValue: 500,
            iconName: "trophy.fill"
        ),

        // Nutrition achievements
        Achievement(
            id: "nutrition_log_7",
            title: "Mindful Eater",
            description: "Log meals for 7 days",
            tier: .bronze,
            category: .nutrition,
            targetValue: 7,
            iconName: "fork.knife"
        ),
        Achievement(
            id: "nutrition_log_30",
            title: "Nutrition Tracker",
            description: "Log meals for 30 days",
            tier: .silver,
            category: .nutrition,
            targetValue: 30,
            iconName: "fork.knife"
        ),
        Achievement(
            id: "nutrition_protein_7",
            title: "Protein Pro",
            description: "Hit protein goals 7 days in a row",
            tier: .silver,
            category: .nutrition,
            targetValue: 7,
            iconName: "bolt.fill"
        ),

        // Hydration achievements
        Achievement(
            id: "hydration_first",
            title: "Stay Hydrated",
            description: "Meet your hydration goal",
            tier: .bronze,
            category: .hydration,
            targetValue: 1,
            iconName: "drop.fill"
        ),
        Achievement(
            id: "hydration_7",
            title: "Water Week",
            description: "Meet hydration goals for 7 days",
            tier: .silver,
            category: .hydration,
            targetValue: 7,
            iconName: "drop.fill"
        ),
        Achievement(
            id: "hydration_30",
            title: "Hydration Hero",
            description: "Meet hydration goals for 30 days",
            tier: .gold,
            category: .hydration,
            targetValue: 30,
            iconName: "drop.circle.fill"
        ),

        // Milestone achievements
        Achievement(
            id: "weight_first",
            title: "Weigh In",
            description: "Log your first weight entry",
            tier: .bronze,
            category: .milestone,
            targetValue: 1,
            iconName: "scalemass.fill"
        ),
        Achievement(
            id: "goal_reached",
            title: "Goal Crusher",
            description: "Reach your weight goal",
            tier: .platinum,
            category: .milestone,
            targetValue: 1,
            iconName: "star.fill"
        ),

        // Challenge achievements
        Achievement(
            id: "challenge_first",
            title: "Challenger",
            description: "Complete your first challenge",
            tier: .bronze,
            category: .challenge,
            targetValue: 1,
            iconName: "flag.fill"
        ),
        Achievement(
            id: "challenge_5",
            title: "Challenge Accepted",
            description: "Complete 5 challenges",
            tier: .silver,
            category: .challenge,
            targetValue: 5,
            iconName: "flag.checkered"
        ),
        Achievement(
            id: "challenge_10",
            title: "Challenge Champion",
            description: "Complete 10 challenges",
            tier: .gold,
            category: .challenge,
            targetValue: 10,
            iconName: "trophy.fill"
        )
    ]

    // MARK: - Initialize Achievements

    func initializeAchievementsIfNeeded() {
        var achievements = persistence.loadAchievements()

        for definition in Self.allAchievementDefinitions {
            if !achievements.contains(where: { $0.id == definition.id }) {
                achievements.append(definition)
            }
        }

        persistence.saveAchievements(achievements)
    }

    // MARK: - Get Achievements

    func getAllAchievements() -> [Achievement] {
        let saved = persistence.loadAchievements()
        if saved.isEmpty {
            initializeAchievementsIfNeeded()
            return persistence.loadAchievements()
        }
        return saved
    }

    func getUnlockedAchievements() -> [Achievement] {
        getAllAchievements().filter { $0.isUnlocked }
    }

    func getLockedAchievements() -> [Achievement] {
        getAllAchievements().filter { !$0.isUnlocked }
    }

    func getAchievements(by category: AchievementCategory) -> [Achievement] {
        getAllAchievements().filter { $0.category == category }
    }

    func getAchievements(by tier: AchievementTier) -> [Achievement] {
        getAllAchievements().filter { $0.tier == tier }
    }

    func getRecentlyUnlocked(within days: Int = 7) -> [Achievement] {
        persistence.getRecentlyUnlockedAchievements(within: days)
    }

    func getNextToUnlock() -> [Achievement] {
        getLockedAchievements()
            .sorted { $0.progress > $1.progress }
            .prefix(3)
            .map { $0 }
    }

    // MARK: - Update Progress

    func updateStreakProgress() {
        let streaks = streakService.getAllStreaks()
        let maxStreak = streaks.map { $0.longestCount }.max() ?? 0

        updateAchievementProgress("streak_3_day", value: min(maxStreak, 3))
        updateAchievementProgress("streak_7_day", value: min(maxStreak, 7))
        updateAchievementProgress("streak_30_day", value: min(maxStreak, 30))
        updateAchievementProgress("streak_100_day", value: min(maxStreak, 100))
    }

    func updateWorkoutProgress(totalWorkouts: Int) {
        updateAchievementProgress("workout_first", value: min(totalWorkouts, 1))
        updateAchievementProgress("workout_10", value: min(totalWorkouts, 10))
        updateAchievementProgress("workout_50", value: min(totalWorkouts, 50))
        updateAchievementProgress("workout_100", value: min(totalWorkouts, 100))
        updateAchievementProgress("workout_500", value: min(totalWorkouts, 500))
    }

    func updateNutritionProgress(loggingDays: Int, proteinStreakDays: Int) {
        updateAchievementProgress("nutrition_log_7", value: min(loggingDays, 7))
        updateAchievementProgress("nutrition_log_30", value: min(loggingDays, 30))
        updateAchievementProgress("nutrition_protein_7", value: min(proteinStreakDays, 7))
    }

    func updateHydrationProgress(goalMetDays: Int) {
        updateAchievementProgress("hydration_first", value: min(goalMetDays, 1))
        updateAchievementProgress("hydration_7", value: min(goalMetDays, 7))
        updateAchievementProgress("hydration_30", value: min(goalMetDays, 30))
    }

    func updateChallengeProgress(completedChallenges: Int) {
        updateAchievementProgress("challenge_first", value: min(completedChallenges, 1))
        updateAchievementProgress("challenge_5", value: min(completedChallenges, 5))
        updateAchievementProgress("challenge_10", value: min(completedChallenges, 10))
    }

    func recordWeightEntry() {
        updateAchievementProgress("weight_first", value: 1)
    }

    func recordGoalReached() {
        updateAchievementProgress("goal_reached", value: 1)
    }

    private func updateAchievementProgress(_ id: String, value: Int) {
        var achievements = getAllAchievements()
        guard let index = achievements.firstIndex(where: { $0.id == id }) else { return }

        let wasUnlocked = achievements[index].isUnlocked
        achievements[index].updateProgress(value)

        if !wasUnlocked && achievements[index].isUnlocked {
            // Achievement just unlocked
            NotificationCenter.default.post(
                name: .achievementUnlocked,
                object: achievements[index]
            )
        }

        persistence.saveAchievements(achievements)
    }

    // MARK: - Achievement Summary

    func getAchievementSummary() -> AchievementSummary {
        let all = getAllAchievements()
        let unlocked = all.filter { $0.isUnlocked }
        let recent = getRecentlyUnlocked(within: 7)
        let nextUp = getNextToUnlock()

        return AchievementSummary(
            totalAchievements: all.count,
            unlockedCount: unlocked.count,
            recentlyUnlocked: recent,
            nextToUnlock: nextUp,
            byCategory: Dictionary(grouping: all, by: { $0.category }),
            byTier: Dictionary(grouping: unlocked, by: { $0.tier })
        )
    }
}

// MARK: - Achievement Summary

struct AchievementSummary {
    let totalAchievements: Int
    let unlockedCount: Int
    let recentlyUnlocked: [Achievement]
    let nextToUnlock: [Achievement]
    let byCategory: [AchievementCategory: [Achievement]]
    let byTier: [AchievementTier: [Achievement]]

    var progress: Double {
        guard totalAchievements > 0 else { return 0 }
        return Double(unlockedCount) / Double(totalAchievements)
    }

    var hasRecentUnlock: Bool {
        !recentlyUnlocked.isEmpty
    }
}

// MARK: - Notification Name Extension

extension Notification.Name {
    static let achievementUnlocked = Notification.Name("achievementUnlocked")
}
