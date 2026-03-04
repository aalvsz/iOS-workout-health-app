import Foundation

class PersistenceController {
    static let shared = PersistenceController()

    private let userDefaults = UserDefaults.standard

    // Keys
    private enum Keys {
        static let userProfile = "userProfile"
        static let loggedMeals = "loggedMeals"
        static let weightHistory = "weightHistory"
        static let dailySummaries = "dailySummaries"
        static let savedMealPlans = "savedMealPlans"
        static let lastSyncDate = "lastSyncDate"
        static let onboardingCompleted = "onboardingCompleted"
        static let hydrationEntries = "hydrationEntries"

        // Engagement keys
        static let streaks = "streaks"
        static let achievements = "achievements"
        static let activeChallenges = "activeChallenges"
        static let completedChallenges = "completedChallenges"
        static let goalPredictions = "goalPredictions"
        static let scheduledNotifications = "scheduledNotifications"
        static let notificationSettings = "notificationSettings"
        static let workoutTemplates = "workoutTemplates"
    }

    private init() {}

    // MARK: - Cloud Sync Hook

    private func notifyCloudSync(recordType: String, recordID: String?) {
        Task { @MainActor in
            guard AuthService.shared.isSignedIn else { return }
            try? await CloudSyncService.shared.pushRecord(type: recordType, id: recordID)
        }
    }

    // MARK: - Modified At Tracking

    func setModifiedAt(_ date: Date, for recordType: String, id: String) {
        userDefaults.set(date.timeIntervalSince1970, forKey: "modifiedAt_\(recordType)_\(id)")
    }

    func getModifiedAt(for recordType: String, id: String) -> Date? {
        let interval = userDefaults.double(forKey: "modifiedAt_\(recordType)_\(id)")
        return interval > 0 ? Date(timeIntervalSince1970: interval) : nil
    }

    // MARK: - User Profile
    func saveProfile(_ profile: UserProfile) {
        if let encoded = try? JSONEncoder().encode(profile) {
            userDefaults.set(encoded, forKey: Keys.userProfile)
        }
        notifyCloudSync(recordType: "UserProfile", recordID: profile.id.uuidString)
    }

    func loadProfile() -> UserProfile {
        guard let data = userDefaults.data(forKey: Keys.userProfile),
              let profile = try? JSONDecoder().decode(UserProfile.self, from: data) else {
            return UserProfile()
        }
        return profile
    }

    // MARK: - Meals
    func saveMeal(_ meal: Meal) {
        var meals = loadMeals()
        meals.append(meal)
        saveMeals(meals)
        notifyCloudSync(recordType: "Meal", recordID: meal.id.uuidString)
    }

    func loadMeals(for date: Date? = nil) -> [Meal] {
        guard let data = userDefaults.data(forKey: Keys.loggedMeals),
              let meals = try? JSONDecoder().decode([Meal].self, from: data) else {
            return []
        }

        if let date = date {
            let calendar = Calendar.current
            return meals.filter { calendar.isDate($0.date, inSameDayAs: date) }
        }

        return meals
    }

    func loadMealsForWeek() -> [Meal] {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!

        return loadMeals().filter { $0.date >= startOfWeek }
    }

    func deleteMeal(_ meal: Meal) {
        var meals = loadMeals()
        meals.removeAll { $0.id == meal.id }
        saveMeals(meals)
    }

    private func saveMeals(_ meals: [Meal]) {
        if let encoded = try? JSONEncoder().encode(meals) {
            userDefaults.set(encoded, forKey: Keys.loggedMeals)
        }
    }

    // MARK: - Weight History
    func saveWeightEntry(_ entry: WeightEntry) {
        var entries = loadWeightHistory()
        entries.append(entry)
        entries.sort { $0.date < $1.date }

        if let encoded = try? JSONEncoder().encode(entries) {
            userDefaults.set(encoded, forKey: Keys.weightHistory)
        }
        notifyCloudSync(recordType: "WeightEntry", recordID: entry.id.uuidString)
    }

    func loadWeightHistory() -> [WeightEntry] {
        guard let data = userDefaults.data(forKey: Keys.weightHistory),
              let entries = try? JSONDecoder().decode([WeightEntry].self, from: data) else {
            return []
        }
        return entries
    }

    // MARK: - Daily Summaries Cache
    func cacheDailySummaries(_ summaries: [DailyHealthSummary]) {
        if let encoded = try? JSONEncoder().encode(summaries) {
            userDefaults.set(encoded, forKey: Keys.dailySummaries)
            userDefaults.set(Date(), forKey: Keys.lastSyncDate)
        }
    }

    /// Cache a single day's summary, updating or adding it to the existing cache
    func cacheDailySummary(_ summary: DailyHealthSummary) {
        var summaries = loadCachedSummaries()
        let calendar = Calendar.current

        // Remove existing summary for the same day
        summaries.removeAll { calendar.isDate($0.date, inSameDayAs: summary.date) }

        // Add the new summary
        summaries.append(summary)

        // Sort by date and keep last 60 days
        summaries.sort { $0.date < $1.date }
        if summaries.count > 60 {
            summaries = Array(summaries.suffix(60))
        }

        // Save
        if let encoded = try? JSONEncoder().encode(summaries) {
            userDefaults.set(encoded, forKey: Keys.dailySummaries)
            userDefaults.set(Date(), forKey: Keys.lastSyncDate)
        }
    }

    func loadCachedSummaries() -> [DailyHealthSummary] {
        guard let data = userDefaults.data(forKey: Keys.dailySummaries),
              let summaries = try? JSONDecoder().decode([DailyHealthSummary].self, from: data) else {
            return []
        }
        return summaries
    }

    var lastSyncDate: Date? {
        userDefaults.object(forKey: Keys.lastSyncDate) as? Date
    }

    var shouldRefreshData: Bool {
        guard let lastSync = lastSyncDate else { return true }
        let hoursSinceSync = Date().timeIntervalSince(lastSync) / 3600
        return hoursSinceSync > 1 // Refresh if older than 1 hour
    }

    // MARK: - Meal Plans
    func saveMealPlan(_ plan: DayMealPlan) {
        var plans = loadSavedMealPlans()
        plans.removeAll { Calendar.current.isDate($0.date, inSameDayAs: plan.date) }
        plans.append(plan)

        if let encoded = try? JSONEncoder().encode(plans) {
            userDefaults.set(encoded, forKey: Keys.savedMealPlans)
        }
        notifyCloudSync(recordType: "DayMealPlan", recordID: plan.date.ISO8601Format())
    }

    func loadSavedMealPlans() -> [DayMealPlan] {
        guard let data = userDefaults.data(forKey: Keys.savedMealPlans),
              let plans = try? JSONDecoder().decode([DayMealPlan].self, from: data) else {
            return []
        }
        return plans
    }

    func loadMealPlan(for date: Date) -> DayMealPlan? {
        loadSavedMealPlans().first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    // MARK: - Hydration

    func saveHydrationEntry(_ entry: HydrationEntry) {
        var entries = loadAllHydrationEntries()
        entries.append(entry)

        if let encoded = try? JSONEncoder().encode(entries) {
            userDefaults.set(encoded, forKey: Keys.hydrationEntries)
        }
        notifyCloudSync(recordType: "HydrationEntry", recordID: entry.id.uuidString)
    }

    func loadHydrationEntries(for date: Date) -> [HydrationEntry] {
        let calendar = Calendar.current
        return loadAllHydrationEntries().filter { calendar.isDate($0.date, inSameDayAs: date) }
    }

    func loadHydrationEntriesForWeek() -> [HydrationEntry] {
        let calendar = Calendar.current
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) else {
            return []
        }

        return loadAllHydrationEntries().filter { $0.date >= weekAgo }
    }

    func deleteHydrationEntry(_ entry: HydrationEntry) {
        var entries = loadAllHydrationEntries()
        entries.removeAll { $0.id == entry.id }

        if let encoded = try? JSONEncoder().encode(entries) {
            userDefaults.set(encoded, forKey: Keys.hydrationEntries)
        }
    }

    private func loadAllHydrationEntries() -> [HydrationEntry] {
        guard let data = userDefaults.data(forKey: Keys.hydrationEntries),
              let entries = try? JSONDecoder().decode([HydrationEntry].self, from: data) else {
            return []
        }
        return entries
    }

    // MARK: - Onboarding
    var hasCompletedOnboarding: Bool {
        get { userDefaults.bool(forKey: Keys.onboardingCompleted) }
        set { userDefaults.set(newValue, forKey: Keys.onboardingCompleted) }
    }

    // MARK: - Streaks

    func saveStreaks(_ streaks: [Streak]) {
        if let encoded = try? JSONEncoder().encode(streaks) {
            userDefaults.set(encoded, forKey: Keys.streaks)
        }
        for streak in streaks {
            notifyCloudSync(recordType: "Streak", recordID: streak.type.rawValue)
        }
    }

    func loadStreaks() -> [Streak] {
        guard let data = userDefaults.data(forKey: Keys.streaks),
              let streaks = try? JSONDecoder().decode([Streak].self, from: data) else {
            return []
        }
        return streaks
    }

    func updateStreak(_ streak: Streak) {
        var streaks = loadStreaks()
        if let index = streaks.firstIndex(where: { $0.type == streak.type }) {
            streaks[index] = streak
        } else {
            streaks.append(streak)
        }
        saveStreaks(streaks)
    }

    func getStreak(for type: StreakType) -> Streak? {
        loadStreaks().first { $0.type == type }
    }

    // MARK: - Achievements

    func saveAchievements(_ achievements: [Achievement]) {
        if let encoded = try? JSONEncoder().encode(achievements) {
            userDefaults.set(encoded, forKey: Keys.achievements)
        }
        for achievement in achievements {
            notifyCloudSync(recordType: "Achievement", recordID: achievement.id)
        }
    }

    func loadAchievements() -> [Achievement] {
        guard let data = userDefaults.data(forKey: Keys.achievements),
              let achievements = try? JSONDecoder().decode([Achievement].self, from: data) else {
            return []
        }
        return achievements
    }

    func updateAchievement(_ achievement: Achievement) {
        var achievements = loadAchievements()
        if let index = achievements.firstIndex(where: { $0.id == achievement.id }) {
            achievements[index] = achievement
        } else {
            achievements.append(achievement)
        }
        saveAchievements(achievements)
    }

    func unlockAchievement(_ id: String) {
        var achievements = loadAchievements()
        if let index = achievements.firstIndex(where: { $0.id == id }) {
            achievements[index].unlockedDate = Date()
            achievements[index].currentProgress = achievements[index].targetValue
            saveAchievements(achievements)
        }
    }

    func getAchievement(_ id: String) -> Achievement? {
        loadAchievements().first { $0.id == id }
    }

    func getUnlockedAchievements() -> [Achievement] {
        loadAchievements().filter { $0.isUnlocked }
    }

    func getRecentlyUnlockedAchievements(within days: Int = 7) -> [Achievement] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return loadAchievements().filter { achievement in
            guard let unlockedDate = achievement.unlockedDate else { return false }
            return unlockedDate >= cutoff
        }
    }

    // MARK: - Challenges

    func saveChallenge(_ challenge: Challenge) {
        var challenges = loadActiveChallenges()
        if let index = challenges.firstIndex(where: { $0.id == challenge.id }) {
            challenges[index] = challenge
        } else {
            challenges.append(challenge)
        }

        if challenge.isCompleted {
            // Move to completed
            challenges.removeAll { $0.id == challenge.id }
            var completed = loadCompletedChallenges()
            completed.append(challenge)
            if let encoded = try? JSONEncoder().encode(completed) {
                userDefaults.set(encoded, forKey: Keys.completedChallenges)
            }
            notifyCloudSync(recordType: "CompletedChallenge", recordID: challenge.id.uuidString)
        } else {
            notifyCloudSync(recordType: "ActiveChallenge", recordID: challenge.id.uuidString)
        }

        if let encoded = try? JSONEncoder().encode(challenges) {
            userDefaults.set(encoded, forKey: Keys.activeChallenges)
        }
    }

    func loadActiveChallenges() -> [Challenge] {
        guard let data = userDefaults.data(forKey: Keys.activeChallenges),
              let challenges = try? JSONDecoder().decode([Challenge].self, from: data) else {
            return []
        }
        return challenges.filter { !$0.isExpired }
    }

    func loadCompletedChallenges() -> [Challenge] {
        guard let data = userDefaults.data(forKey: Keys.completedChallenges),
              let challenges = try? JSONDecoder().decode([Challenge].self, from: data) else {
            return []
        }
        return challenges
    }

    func getActiveChallenge() -> Challenge? {
        loadActiveChallenges().first { $0.isActive }
    }

    func deleteChallenge(_ challenge: Challenge) {
        var challenges = loadActiveChallenges()
        challenges.removeAll { $0.id == challenge.id }
        if let encoded = try? JSONEncoder().encode(challenges) {
            userDefaults.set(encoded, forKey: Keys.activeChallenges)
        }
    }

    // MARK: - Goal Predictions

    func saveGoalPrediction(_ prediction: GoalPrediction) {
        var predictions = loadGoalPredictions()
        if let index = predictions.firstIndex(where: { $0.goalType == prediction.goalType }) {
            predictions[index] = prediction
        } else {
            predictions.append(prediction)
        }

        if let encoded = try? JSONEncoder().encode(predictions) {
            userDefaults.set(encoded, forKey: Keys.goalPredictions)
        }
        notifyCloudSync(recordType: "GoalPrediction", recordID: prediction.goalType.rawValue)
    }

    func loadGoalPredictions() -> [GoalPrediction] {
        guard let data = userDefaults.data(forKey: Keys.goalPredictions),
              let predictions = try? JSONDecoder().decode([GoalPrediction].self, from: data) else {
            return []
        }
        return predictions
    }

    func getGoalPrediction(for type: GoalType) -> GoalPrediction? {
        loadGoalPredictions().first { $0.goalType == type }
    }

    // MARK: - Notifications

    func saveScheduledNotification(_ notification: CoachNotification) {
        var notifications = loadScheduledNotifications()
        notifications.append(notification)
        if let encoded = try? JSONEncoder().encode(notifications) {
            userDefaults.set(encoded, forKey: Keys.scheduledNotifications)
        }
    }

    func loadScheduledNotifications() -> [CoachNotification] {
        guard let data = userDefaults.data(forKey: Keys.scheduledNotifications),
              let notifications = try? JSONDecoder().decode([CoachNotification].self, from: data) else {
            return []
        }
        return notifications
    }

    func markNotificationDelivered(_ id: UUID) {
        var notifications = loadScheduledNotifications()
        if let index = notifications.firstIndex(where: { $0.id == id }) {
            notifications[index].isDelivered = true
            if let encoded = try? JSONEncoder().encode(notifications) {
                userDefaults.set(encoded, forKey: Keys.scheduledNotifications)
            }
        }
    }

    func markNotificationTapped(_ id: UUID) {
        var notifications = loadScheduledNotifications()
        if let index = notifications.firstIndex(where: { $0.id == id }) {
            notifications[index].isTapped = true
            if let encoded = try? JSONEncoder().encode(notifications) {
                userDefaults.set(encoded, forKey: Keys.scheduledNotifications)
            }
        }
    }

    func clearOldNotifications(olderThan days: Int = 30) {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        var notifications = loadScheduledNotifications()
        notifications.removeAll { $0.scheduledDate < cutoff }
        if let encoded = try? JSONEncoder().encode(notifications) {
            userDefaults.set(encoded, forKey: Keys.scheduledNotifications)
        }
    }

    // MARK: - Notification Settings

    func saveNotificationSettings(enabled: Bool, types: [CoachNotificationType]) {
        let settings: [String: Any] = [
            "enabled": enabled,
            "types": types.map { $0.rawValue }
        ]
        userDefaults.set(settings, forKey: Keys.notificationSettings)
        notifyCloudSync(recordType: "NotificationSettings", recordID: "default")
    }

    func loadNotificationSettings() -> (enabled: Bool, types: [CoachNotificationType]) {
        guard let settings = userDefaults.dictionary(forKey: Keys.notificationSettings) else {
            return (true, CoachNotificationType.allCases) // Default: all enabled
        }

        let enabled = settings["enabled"] as? Bool ?? true
        let typeStrings = settings["types"] as? [String] ?? []
        let types = typeStrings.compactMap { CoachNotificationType(rawValue: $0) }

        return (enabled, types.isEmpty ? CoachNotificationType.allCases : types)
    }

    // MARK: - Workout Templates

    func saveWorkoutTemplate(_ template: WorkoutTemplate) {
        var templates = loadWorkoutTemplates()
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            templates[index] = template
        } else {
            templates.append(template)
        }
        if let encoded = try? JSONEncoder().encode(templates) {
            userDefaults.set(encoded, forKey: Keys.workoutTemplates)
        }
        notifyCloudSync(recordType: "WorkoutTemplate", recordID: template.id.uuidString)
    }

    func loadWorkoutTemplates() -> [WorkoutTemplate] {
        guard let data = userDefaults.data(forKey: Keys.workoutTemplates),
              let templates = try? JSONDecoder().decode([WorkoutTemplate].self, from: data) else {
            return []
        }
        return templates
    }

    func deleteWorkoutTemplate(_ template: WorkoutTemplate) {
        var templates = loadWorkoutTemplates()
        templates.removeAll { $0.id == template.id }
        if let encoded = try? JSONEncoder().encode(templates) {
            userDefaults.set(encoded, forKey: Keys.workoutTemplates)
        }
    }

    // MARK: - Clear All Data
    func clearAllData() {
        let domain = Bundle.main.bundleIdentifier!
        userDefaults.removePersistentDomain(forName: domain)
        userDefaults.synchronize()
    }
}

// MARK: - Codable Extension for DayMealPlan
extension DayMealPlan: Codable {
    enum CodingKeys: String, CodingKey {
        case date, breakfast, lunch, dinner, snacks, targets
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        date = try container.decode(Date.self, forKey: .date)
        breakfast = try container.decodeIfPresent(MealSuggestion.self, forKey: .breakfast)
        lunch = try container.decodeIfPresent(MealSuggestion.self, forKey: .lunch)
        dinner = try container.decodeIfPresent(MealSuggestion.self, forKey: .dinner)
        snacks = try container.decode([MealSuggestion].self, forKey: .snacks)
        targets = try container.decode(NutritionTargets.self, forKey: .targets)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(date, forKey: .date)
        try container.encodeIfPresent(breakfast, forKey: .breakfast)
        try container.encodeIfPresent(lunch, forKey: .lunch)
        try container.encodeIfPresent(dinner, forKey: .dinner)
        try container.encode(snacks, forKey: .snacks)
        try container.encode(targets, forKey: .targets)
    }
}
