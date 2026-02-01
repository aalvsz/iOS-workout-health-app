import Foundation
import Combine

@MainActor
class EngagementViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var streaks: [Streak] = []
    @Published var achievements: [Achievement] = []
    @Published var activeChallenge: Challenge?
    @Published var goalPrediction: GoalPrediction?
    @Published var isLoading = false

    // Celebration states
    @Published var showStreakCelebration = false
    @Published var celebratingStreak: Streak?
    @Published var celebratingMilestone: String?

    @Published var showAchievementUnlock = false
    @Published var unlockedAchievement: Achievement?

    @Published var showChallengeComplete = false
    @Published var completedChallenge: Challenge?

    // MARK: - Dependencies
    private let streakService = StreakService.shared
    private let achievementService = AchievementService.shared
    private let challengeService = ChallengeService.shared
    private let goalPredictionService = GoalPredictionService.shared
    private let persistence = PersistenceController.shared

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    var streakSummary: StreakSummary {
        streakService.getStreakSummary()
    }

    var achievementSummary: AchievementSummary {
        achievementService.getAchievementSummary()
    }

    var challengeStats: ChallengeStats {
        challengeService.getChallengeStats()
    }

    var unlockedAchievements: [Achievement] {
        achievements.filter { $0.isUnlocked }
    }

    var lockedAchievements: [Achievement] {
        achievements.filter { !$0.isUnlocked }
    }

    var hasActiveStreak: Bool {
        streaks.contains { $0.currentCount > 0 && $0.isActive }
    }

    var streakAtRisk: Streak? {
        streaks.first { $0.isAtRisk && $0.currentCount > 0 }
    }

    // MARK: - Initialization

    init() {
        setupNotificationObservers()
    }

    private func setupNotificationObservers() {
        // Listen for achievement unlocks
        NotificationCenter.default.publisher(for: .achievementUnlocked)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                if let achievement = notification.object as? Achievement {
                    self?.handleAchievementUnlock(achievement)
                }
            }
            .store(in: &cancellables)

        // Listen for challenge completions
        NotificationCenter.default.publisher(for: .challengeCompleted)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                if let challenge = notification.object as? Challenge {
                    self?.handleChallengeComplete(challenge)
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Data Loading

    func loadData() async {
        isLoading = true

        // Load all engagement data
        streaks = streakService.getAllStreaks()
        achievements = achievementService.getAllAchievements()
        activeChallenge = challengeService.getActiveChallenge()

        // Update challenge progress if active
        if activeChallenge != nil {
            challengeService.updateChallengeProgress()
            activeChallenge = challengeService.getActiveChallenge()
        }

        // Load goal prediction
        let profile = persistence.loadProfile()
        goalPrediction = goalPredictionService.refreshPrediction(profile: profile)

        isLoading = false
    }

    func refreshData() async {
        await loadData()
    }

    // MARK: - Streak Actions

    func checkStreaks(workoutCount: Int, mealsLogged: Int, weightLogged: Bool, steps: Int, profile: UserProfile) {
        // Check and record activities
        streakService.checkWorkoutActivity(workoutCount: workoutCount)
        streakService.checkLoggingActivity(mealsLogged: mealsLogged, weightLogged: weightLogged)
        streakService.checkHydrationGoal(profile: profile, todayActivity: nil)
        streakService.checkStepGoal(steps: steps)

        // Reload streaks
        streaks = streakService.getAllStreaks()

        // Check for milestone celebrations
        for streak in streaks {
            if let milestone = streakService.getStreakMilestone(for: streak.currentCount) {
                // Check if this milestone was just reached today
                let calendar = Calendar.current
                if calendar.isDateInToday(streak.lastActivityDate) {
                    celebratingStreak = streak
                    celebratingMilestone = milestone
                    showStreakCelebration = true
                    break
                }
            }
        }

        // Update achievement progress
        achievementService.updateStreakProgress()
        achievements = achievementService.getAllAchievements()
    }

    // MARK: - Challenge Actions

    func joinWeeklyChallenge() {
        let profile = persistence.loadProfile()
        activeChallenge = challengeService.joinWeeklyChallenge(profile: profile)
    }

    func abandonChallenge() {
        challengeService.abandonChallenge()
        activeChallenge = nil
    }

    // MARK: - Achievement Actions

    func getAchievements(by category: AchievementCategory) -> [Achievement] {
        achievements.filter { $0.category == category }
    }

    func getAchievements(by tier: AchievementTier) -> [Achievement] {
        achievements.filter { $0.tier == tier }
    }

    // MARK: - Celebration Handlers

    private func handleAchievementUnlock(_ achievement: Achievement) {
        unlockedAchievement = achievement
        showAchievementUnlock = true

        // Refresh achievements
        achievements = achievementService.getAllAchievements()
    }

    private func handleChallengeComplete(_ challenge: Challenge) {
        completedChallenge = challenge
        showChallengeComplete = true

        // Clear active challenge
        activeChallenge = nil
    }

    func dismissStreakCelebration() {
        showStreakCelebration = false
        celebratingStreak = nil
        celebratingMilestone = nil
    }

    func dismissAchievementUnlock() {
        showAchievementUnlock = false
        unlockedAchievement = nil
    }

    func dismissChallengeComplete() {
        showChallengeComplete = false
        completedChallenge = nil
    }

    // MARK: - Engagement Summary

    func getEngagementSummary() -> EngagementSummary {
        let activeStreaks = streaks.filter { $0.currentCount > 0 && $0.isActive }
        let longestStreak = streaks.max { $0.longestCount < $1.longestCount }
        let recentAchievements = achievementService.getRecentlyUnlocked(within: 7)
        let unlockedCount = achievements.filter { $0.isUnlocked }.count

        return EngagementSummary(
            activeStreaks: activeStreaks,
            longestStreak: longestStreak,
            recentAchievements: recentAchievements,
            unlockedCount: unlockedCount,
            totalAchievements: achievements.count,
            activeChallenge: activeChallenge,
            goalPrediction: goalPrediction
        )
    }
}
