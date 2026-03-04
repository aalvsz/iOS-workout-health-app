import Foundation

// MARK: - Streak Types
enum StreakType: String, Codable, CaseIterable {
    case workout = "Workout"
    case logging = "Logging"
    case hydration = "Hydration"
    case steps = "Steps"
    case overall = "Overall"

    var displayName: String {
        switch self {
        case .workout: return String(localized: "Workout")
        case .logging: return String(localized: "Logging")
        case .hydration: return String(localized: "Hydration")
        case .steps: return String(localized: "Steps")
        case .overall: return String(localized: "Overall")
        }
    }

    var icon: String {
        switch self {
        case .workout: return "flame.fill"
        case .logging: return "square.and.pencil"
        case .hydration: return "drop.fill"
        case .steps: return "figure.walk"
        case .overall: return "star.fill"
        }
    }

    var color: String {
        switch self {
        case .workout: return "streakWorkout"
        case .logging: return "streakLogging"
        case .hydration: return "streakHydration"
        case .steps: return "streakSteps"
        case .overall: return "streakOverall"
        }
    }

    var description: String {
        switch self {
        case .workout: return String(localized: "Complete at least one workout")
        case .logging: return String(localized: "Log a meal or weight entry")
        case .hydration: return String(localized: "Meet your hydration goal")
        case .steps: return String(localized: "Reach your step goal")
        case .overall: return String(localized: "Stay active across all areas")
        }
    }
}

// MARK: - Streak
struct Streak: Identifiable, Codable {
    let id: UUID
    let type: StreakType
    var currentCount: Int
    var longestCount: Int
    var lastActivityDate: Date
    var startDate: Date

    init(
        id: UUID = UUID(),
        type: StreakType,
        currentCount: Int = 0,
        longestCount: Int = 0,
        lastActivityDate: Date = Date(),
        startDate: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.currentCount = currentCount
        self.longestCount = longestCount
        self.lastActivityDate = lastActivityDate
        self.startDate = startDate
    }

    var isActive: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastActive = calendar.startOfDay(for: lastActivityDate)

        // Active if last activity was today or yesterday
        guard let daysSince = calendar.dateComponents([.day], from: lastActive, to: today).day else {
            return false
        }
        return daysSince <= 1
    }

    var isAtRisk: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastActive = calendar.startOfDay(for: lastActivityDate)

        // At risk if last activity was yesterday and today is almost over
        guard let daysSince = calendar.dateComponents([.day], from: lastActive, to: today).day else {
            return false
        }

        if daysSince == 1 {
            let hour = calendar.component(.hour, from: Date())
            return hour >= 20 // After 8 PM
        }
        return false
    }

    mutating func recordActivity() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastActive = calendar.startOfDay(for: lastActivityDate)

        guard let daysSince = calendar.dateComponents([.day], from: lastActive, to: today).day else {
            return
        }

        if daysSince == 0 {
            // Already recorded today, no change
            return
        } else if daysSince == 1 {
            // Consecutive day
            currentCount += 1
        } else {
            // Streak broken, start fresh
            currentCount = 1
            startDate = today
        }

        lastActivityDate = Date()
        longestCount = max(longestCount, currentCount)
    }

    mutating func checkAndResetIfBroken() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastActive = calendar.startOfDay(for: lastActivityDate)

        guard let daysSince = calendar.dateComponents([.day], from: lastActive, to: today).day else {
            return
        }

        if daysSince > 1 {
            // Streak is broken
            currentCount = 0
        }
    }
}

// MARK: - Achievement Tier
enum AchievementTier: String, Codable, CaseIterable {
    case bronze = "Bronze"
    case silver = "Silver"
    case gold = "Gold"
    case platinum = "Platinum"

    var displayName: String {
        switch self {
        case .bronze: return String(localized: "Bronze")
        case .silver: return String(localized: "Silver")
        case .gold: return String(localized: "Gold")
        case .platinum: return String(localized: "Platinum")
        }
    }

    var color: String {
        switch self {
        case .bronze: return "tierBronze"
        case .silver: return "tierSilver"
        case .gold: return "tierGold"
        case .platinum: return "tierPlatinum"
        }
    }

    var icon: String {
        switch self {
        case .bronze: return "medal.fill"
        case .silver: return "medal.fill"
        case .gold: return "medal.fill"
        case .platinum: return "crown.fill"
        }
    }
}

// MARK: - Achievement Category
enum AchievementCategory: String, Codable, CaseIterable {
    case streak = "Streaks"
    case workout = "Workouts"
    case nutrition = "Nutrition"
    case hydration = "Hydration"
    case milestone = "Milestones"
    case challenge = "Challenges"

    var displayName: String {
        switch self {
        case .streak: return String(localized: "Streaks")
        case .workout: return String(localized: "Workouts")
        case .nutrition: return String(localized: "Nutrition")
        case .hydration: return String(localized: "Hydration")
        case .milestone: return String(localized: "Milestones")
        case .challenge: return String(localized: "Challenges")
        }
    }

    var icon: String {
        switch self {
        case .streak: return "flame.fill"
        case .workout: return "figure.run"
        case .nutrition: return "fork.knife"
        case .hydration: return "drop.fill"
        case .milestone: return "flag.fill"
        case .challenge: return "trophy.fill"
        }
    }
}

// MARK: - Achievement
struct Achievement: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let tier: AchievementTier
    let category: AchievementCategory
    let targetValue: Int
    var currentProgress: Int
    var unlockedDate: Date?
    let iconName: String

    var isUnlocked: Bool {
        unlockedDate != nil
    }

    var progress: Double {
        guard targetValue > 0 else { return 0 }
        return min(1.0, Double(currentProgress) / Double(targetValue))
    }

    init(
        id: String,
        title: String,
        description: String,
        tier: AchievementTier,
        category: AchievementCategory,
        targetValue: Int,
        currentProgress: Int = 0,
        unlockedDate: Date? = nil,
        iconName: String = "star.fill"
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.tier = tier
        self.category = category
        self.targetValue = targetValue
        self.currentProgress = currentProgress
        self.unlockedDate = unlockedDate
        self.iconName = iconName
    }

    mutating func updateProgress(_ value: Int) {
        currentProgress = value
        if currentProgress >= targetValue && unlockedDate == nil {
            unlockedDate = Date()
        }
    }
}

// MARK: - Challenge Type
enum ChallengeType: String, Codable, CaseIterable {
    case workout = "Workout"
    case steps = "Steps"
    case calories = "Calories"
    case hydration = "Hydration"
    case logging = "Logging"

    var displayName: String {
        switch self {
        case .workout: return String(localized: "Workout")
        case .steps: return String(localized: "Steps")
        case .calories: return String(localized: "Calories")
        case .hydration: return String(localized: "Hydration")
        case .logging: return String(localized: "Logging")
        }
    }

    var icon: String {
        switch self {
        case .workout: return "figure.run"
        case .steps: return "figure.walk"
        case .calories: return "flame.fill"
        case .hydration: return "drop.fill"
        case .logging: return "square.and.pencil"
        }
    }

    var color: String {
        switch self {
        case .workout: return "challengeWorkout"
        case .steps: return "challengeSteps"
        case .calories: return "challengeCalories"
        case .hydration: return "challengeHydration"
        case .logging: return "challengeLogging"
        }
    }

    var unit: String {
        switch self {
        case .workout: return String(localized: "workouts")
        case .steps: return String(localized: "steps")
        case .calories: return String(localized: "kcal")
        case .hydration: return String(localized: "ml")
        case .logging: return String(localized: "days")
        }
    }
}

// MARK: - Challenge
struct Challenge: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let type: ChallengeType
    let target: Int
    var progress: Int
    let startDate: Date
    let endDate: Date
    var isCompleted: Bool
    var completedDate: Date?

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        type: ChallengeType,
        target: Int,
        progress: Int = 0,
        startDate: Date = Date(),
        endDate: Date,
        isCompleted: Bool = false,
        completedDate: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.type = type
        self.target = target
        self.progress = progress
        self.startDate = startDate
        self.endDate = endDate
        self.isCompleted = isCompleted
        self.completedDate = completedDate
    }

    var progressPercentage: Double {
        guard target > 0 else { return 0 }
        return min(1.0, Double(progress) / Double(target))
    }

    var isActive: Bool {
        let now = Date()
        return now >= startDate && now <= endDate && !isCompleted
    }

    var isExpired: Bool {
        Date() > endDate && !isCompleted
    }

    var timeRemaining: TimeInterval {
        max(0, endDate.timeIntervalSince(Date()))
    }

    var formattedTimeRemaining: String {
        let remaining = timeRemaining
        let days = Int(remaining / 86400)
        let hours = Int((remaining.truncatingRemainder(dividingBy: 86400)) / 3600)

        if days > 0 {
            return "\(days)d \(hours)h"
        } else if hours > 0 {
            let minutes = Int((remaining.truncatingRemainder(dividingBy: 3600)) / 60)
            return "\(hours)h \(minutes)m"
        } else {
            let minutes = Int(remaining / 60)
            return "\(minutes)m"
        }
    }

    mutating func updateProgress(_ value: Int) {
        progress = value
        if progress >= target && !isCompleted {
            isCompleted = true
            completedDate = Date()
        }
    }
}

// MARK: - Trend Direction
enum TrendDirection: String, Codable {
    case improving = "Improving"
    case steady = "Steady"
    case declining = "Declining"

    var displayName: String {
        switch self {
        case .improving: return String(localized: "Improving")
        case .steady: return String(localized: "Steady")
        case .declining: return String(localized: "Declining")
        }
    }

    var icon: String {
        switch self {
        case .improving: return "arrow.up.right"
        case .steady: return "arrow.right"
        case .declining: return "arrow.down.right"
        }
    }

    var color: String {
        switch self {
        case .improving: return "trendImproving"
        case .steady: return "trendSteady"
        case .declining: return "trendDeclining"
        }
    }
}

// MARK: - Goal Type
enum GoalType: String, Codable, CaseIterable {
    case weightLoss = "Weight Loss"
    case weightGain = "Weight Gain"
    case maintenance = "Maintenance"
    case fitness = "Fitness"

    var icon: String {
        switch self {
        case .weightLoss: return "arrow.down.circle.fill"
        case .weightGain: return "arrow.up.circle.fill"
        case .maintenance: return "equal.circle.fill"
        case .fitness: return "heart.circle.fill"
        }
    }
}

// MARK: - Goal Prediction
struct GoalPrediction: Identifiable, Codable {
    let id: UUID
    let goalType: GoalType
    let currentValue: Double
    let targetValue: Double
    let unit: String
    let predictedCompletionDate: Date?
    let trendDirection: TrendDirection
    let weeklyChange: Double
    let confidenceLevel: Double // 0-1
    let lastUpdated: Date

    init(
        id: UUID = UUID(),
        goalType: GoalType,
        currentValue: Double,
        targetValue: Double,
        unit: String = "kg",
        predictedCompletionDate: Date? = nil,
        trendDirection: TrendDirection = .steady,
        weeklyChange: Double = 0,
        confidenceLevel: Double = 0.5,
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.goalType = goalType
        self.currentValue = currentValue
        self.targetValue = targetValue
        self.unit = unit
        self.predictedCompletionDate = predictedCompletionDate
        self.trendDirection = trendDirection
        self.weeklyChange = weeklyChange
        self.confidenceLevel = confidenceLevel
        self.lastUpdated = lastUpdated
    }

    var progressPercentage: Double {
        guard targetValue != currentValue else { return 1.0 }

        // For weight loss, we use trend-based progress
        if goalType == .weightLoss {
            let totalToLose = currentValue - targetValue
            if totalToLose <= 0 { return 1.0 }
            // Progress based on how much has been lost relative to weekly rate
            // This is a simplified view - real progress would need start value
            return confidenceLevel
        }

        // For weight gain, lower current means less progress
        return min(1.0, max(0, currentValue / targetValue))
    }

    var isOnTrack: Bool {
        predictedCompletionDate != nil && trendDirection != .declining
    }

    var formattedPrediction: String? {
        guard let date = predictedCompletionDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    var weeksRemaining: Int? {
        guard let date = predictedCompletionDate else { return nil }
        let weeks = Calendar.current.dateComponents([.weekOfYear], from: Date(), to: date).weekOfYear ?? 0
        return max(0, weeks)
    }
}

// MARK: - Coach Notification Type
enum CoachNotificationType: String, Codable, CaseIterable {
    case morningMotivation = "Morning Motivation"
    case hydrationReminder = "Hydration Reminder"
    case streakAtRisk = "Streak at Risk"
    case achievementUnlock = "Achievement Unlock"
    case challengeUpdate = "Challenge Update"
    case workoutReminder = "Workout Reminder"
    case goalMilestone = "Goal Milestone"

    var icon: String {
        switch self {
        case .morningMotivation: return "sun.max.fill"
        case .hydrationReminder: return "drop.fill"
        case .streakAtRisk: return "flame.fill"
        case .achievementUnlock: return "trophy.fill"
        case .challengeUpdate: return "flag.fill"
        case .workoutReminder: return "figure.run"
        case .goalMilestone: return "star.fill"
        }
    }
}

// MARK: - Notification Action Type
enum NotificationActionType: String, Codable {
    case openApp = "Open App"
    case logWater = "Log Water"
    case startWorkout = "Start Workout"
    case viewAchievements = "View Achievements"
    case viewChallenge = "View Challenge"
    case viewProgress = "View Progress"
}

// MARK: - Coach Notification
struct CoachNotification: Identifiable, Codable {
    let id: UUID
    let type: CoachNotificationType
    let title: String
    let body: String
    let scheduledDate: Date
    let actionType: NotificationActionType
    var isDelivered: Bool
    var isTapped: Bool

    init(
        id: UUID = UUID(),
        type: CoachNotificationType,
        title: String,
        body: String,
        scheduledDate: Date,
        actionType: NotificationActionType = .openApp,
        isDelivered: Bool = false,
        isTapped: Bool = false
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.body = body
        self.scheduledDate = scheduledDate
        self.actionType = actionType
        self.isDelivered = isDelivered
        self.isTapped = isTapped
    }
}

// MARK: - Engagement Summary
struct EngagementSummary {
    let activeStreaks: [Streak]
    let longestStreak: Streak?
    let recentAchievements: [Achievement]
    let unlockedCount: Int
    let totalAchievements: Int
    let activeChallenge: Challenge?
    let goalPrediction: GoalPrediction?

    var hasActiveStreak: Bool {
        activeStreaks.contains { $0.currentCount > 0 && $0.isActive }
    }

    var streakAtRisk: Streak? {
        activeStreaks.first { $0.isAtRisk }
    }

    var achievementProgress: Double {
        guard totalAchievements > 0 else { return 0 }
        return Double(unlockedCount) / Double(totalAchievements)
    }
}
