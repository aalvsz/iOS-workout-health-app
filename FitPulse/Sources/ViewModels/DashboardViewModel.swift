import Foundation
import Combine

@MainActor
class DashboardViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var todaySummary: DailyHealthSummary?
    @Published var weekSummaries: [DailyHealthSummary] = []
    @Published var recentWorkouts: [Workout] = []
    @Published var recoveryAnalysis: RecoveryAnalysis?
    @Published var nutritionTargets: NutritionTargets?
    @Published var insights: [Insight] = []
    @Published var isLoading = false
    @Published var error: String?

    // MARK: - Dependencies
    private let healthService = HealthKitService.shared
    private let nutritionCalculator = NutritionCalculator.shared
    private let recoveryAnalyzer = RecoveryAnalyzer.shared
    private let persistence = PersistenceController.shared

    private var healthUpdateObserver: NSObjectProtocol?

    // MARK: - Computed Properties
    var profile: UserProfile {
        persistence.loadProfile()
    }

    var todayStepsProgress: Double {
        guard let today = todaySummary else { return 0 }
        return Double(today.steps) / Double(profile.dailyStepsGoal)
    }

    var todayCaloriesProgress: Double {
        guard let today = todaySummary, let targets = nutritionTargets else { return 0 }
        return today.activeCalories / targets.targetCalories
    }

    var weeklyWorkoutCount: Int {
        let calendar = Calendar.current
        let startOfWeek = Date().startOfWeek
        return recentWorkouts.filter { calendar.isDate($0.date, equalTo: startOfWeek, toGranularity: .weekOfYear) || $0.date >= startOfWeek }.count
    }

    var weeklyWorkoutProgress: Double {
        Double(weeklyWorkoutCount) / Double(profile.weeklyWorkoutGoal)
    }

    // MARK: - Initialization
    init() {
        loadCachedData()
        setupHealthDataObserver()
    }

    deinit {
        if let observer = healthUpdateObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func setupHealthDataObserver() {
        healthUpdateObserver = NotificationCenter.default.addObserver(
            forName: .healthDataDidUpdate,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let summary = notification.object as? DailyHealthSummary {
                Task { @MainActor in
                    self?.handleHealthDataUpdate(summary)
                }
            }
        }
    }

    /// Handle automatic health data update
    private func handleHealthDataUpdate(_ summary: DailyHealthSummary) {
        // Update today's summary
        todaySummary = summary

        // Update in week summaries array
        if let index = weekSummaries.firstIndex(where: {
            Calendar.current.isDate($0.date, inSameDayAs: summary.date)
        }) {
            weekSummaries[index] = summary
        } else {
            weekSummaries.append(summary)
            weekSummaries.sort { $0.date < $1.date }
        }

        // Recalculate dependent data
        calculateNutritionTargets()
        analyzeRecovery()
        generateInsights()
    }

    // MARK: - Data Loading
    func loadData() async {
        isLoading = true
        error = nil

        do {
            // Request HealthKit authorization if needed
            if !healthService.isAuthorized {
                try await healthService.requestAuthorization()
            }

            // Fetch data in parallel
            async let summaries = healthService.fetchDailySummaries(days: 60)
            async let workouts = healthService.fetchRecentWorkouts(limit: 10)

            let fetchedSummaries = try await summaries
            let fetchedWorkouts = try await workouts

            // Update state
            weekSummaries = fetchedSummaries
            todaySummary = fetchedSummaries.last
            recentWorkouts = fetchedWorkouts

            // Cache the data
            persistence.cacheDailySummaries(fetchedSummaries)

            // Calculate nutrition targets
            calculateNutritionTargets()

            // Analyze recovery
            analyzeRecovery()

            // Generate insights
            generateInsights()

        } catch {
            self.error = error.localizedDescription
            print("Error loading dashboard data: \(error)")
        }

        isLoading = false
    }

    func refreshData() async {
        await loadData()
    }

    // MARK: - Private Methods
    private func loadCachedData() {
        let cached = persistence.loadCachedSummaries()
        if !cached.isEmpty {
            weekSummaries = cached
            todaySummary = cached.last
            calculateNutritionTargets()
            analyzeRecovery()
        }
    }

    private func calculateNutritionTargets() {
        nutritionTargets = nutritionCalculator.calculateTargets(
            profile: profile,
            historicalData: weekSummaries
        )
    }

    private func analyzeRecovery() {
        guard let today = todaySummary else { return }

        recoveryAnalysis = recoveryAnalyzer.analyzeRecovery(
            today: today,
            historicalData: weekSummaries
        )
    }

    private func generateInsights() {
        var newInsights: [Insight] = []

        // Recovery insight
        if let recovery = recoveryAnalysis {
            newInsights.append(Insight(
                title: String(localized: "Recovery: \(recovery.status.rawValue)"),
                description: recovery.status.recommendation,
                type: .recovery,
                priority: recovery.status == .critical ? .critical : .medium
            ))

            if recovery.isAnomaly, let reason = recovery.anomalyReason {
                newInsights.append(Insight(
                    title: String(localized: "Unusual Pattern"),
                    description: String(localized: "Today shows unusual values: \(reason)"),
                    type: .anomaly,
                    priority: .high
                ))
            }
        }

        // Workout streak insight
        if weeklyWorkoutCount >= profile.weeklyWorkoutGoal {
            newInsights.append(Insight(
                title: String(localized: "Weekly Goal Achieved!"),
                description: String(localized: "You've hit your \(profile.weeklyWorkoutGoal) workout goal this week."),
                type: .workout,
                priority: .low
            ))
        } else if weeklyWorkoutCount == profile.weeklyWorkoutGoal - 1 {
            newInsights.append(Insight(
                title: String(localized: "Almost There!"),
                description: String(localized: "One more workout to hit your weekly goal."),
                type: .workout,
                priority: .medium,
                actionable: true,
                action: "Start workout"
            ))
        }

        // Sleep insight
        if let today = todaySummary {
            if today.sleepHours < profile.sleepGoalHours - 1 {
                newInsights.append(Insight(
                    title: String(localized: "Sleep Deficit"),
                    description: String(localized: "You slept \(today.sleepHours.formatted1)h, below your \(profile.sleepGoalHours.formatted0)h goal."),
                    type: .sleep,
                    priority: .medium
                ))
            }

            // Steps insight
            let stepsRemaining = profile.dailyStepsGoal - today.steps
            if stepsRemaining > 0 && stepsRemaining < 3000 {
                newInsights.append(Insight(
                    title: String(localized: "\(stepsRemaining.formattedSteps) Steps to Go"),
                    description: String(localized: "A short walk could help you reach your daily goal!"),
                    type: .workout,
                    priority: .low,
                    actionable: true,
                    action: "Track walk"
                ))
            }
        }

        insights = newInsights.sorted { $0.priority > $1.priority }
    }

    // MARK: - Actions
    func logWeight(_ weight: Double) async {
        do {
            try await healthService.saveWeight(weight)
            var updatedProfile = profile
            updatedProfile.weightKg = weight
            persistence.saveProfile(updatedProfile)
            calculateNutritionTargets()
        } catch {
            self.error = String(localized: "Failed to save weight: \(error.localizedDescription)")
        }
    }
}
