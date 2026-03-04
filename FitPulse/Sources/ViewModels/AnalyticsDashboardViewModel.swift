import Foundation
import Combine

@MainActor
class AnalyticsDashboardViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var workoutVolumeData: [ChartDataPoint] = []
    @Published var nutritionAdherenceData: [ChartDataPoint] = []
    @Published var weightData: [ChartDataPoint] = []
    @Published var weightMovingAverage: [ChartDataPoint] = []
    @Published var recoveryData: [ChartDataPoint] = []
    @Published var recoveryInsight: String?
    @Published var isLoadingInsight = false
    @Published var selectedTimeRange: TimeRange = .thirtyDays
    @Published var isLoading = false

    // Engagement (free)
    @Published var engagementViewModel = EngagementViewModel()

    // MARK: - Dependencies
    private let persistence = PersistenceController.shared
    private let llmService = LLMService.shared
    private let nutritionCalculator = NutritionCalculator.shared
    private let recoveryAnalyzer = RecoveryAnalyzer.shared

    // MARK: - Time Range

    enum TimeRange: String, CaseIterable {
        case thirtyDays = "30D"
        case sixtyDays = "60D"
        case ninetyDays = "90D"

        var days: Int {
            switch self {
            case .thirtyDays: return 30
            case .sixtyDays: return 60
            case .ninetyDays: return 90
            }
        }
    }

    // MARK: - Data Loading

    func loadData() async {
        isLoading = true

        let summaries = persistence.loadCachedSummaries()
        let cutoff = Calendar.current.date(byAdding: .day, value: -selectedTimeRange.days, to: Date()) ?? Date()
        let filtered = summaries.filter { $0.date >= cutoff }

        loadWorkoutVolume(from: filtered)
        loadNutritionAdherence(from: filtered)
        loadWeightProgress()
        loadRecoveryScores(from: filtered)

        await engagementViewModel.loadData()

        isLoading = false
    }

    func onTimeRangeChanged() {
        Task {
            await loadData()
        }
    }

    // MARK: - Workout Volume

    private func loadWorkoutVolume(from summaries: [DailyHealthSummary]) {
        // Group by week and sum workout minutes
        let calendar = Calendar.current
        var weeklyData: [(Date, Double)] = []

        let grouped = Dictionary(grouping: summaries) { summary in
            calendar.dateInterval(of: .weekOfYear, for: summary.date)?.start ?? summary.date
        }

        for (weekStart, daySummaries) in grouped.sorted(by: { $0.key < $1.key }) {
            let totalMinutes = daySummaries.reduce(0.0) { $0 + $1.workoutMinutes }
            weeklyData.append((weekStart, totalMinutes))
        }

        workoutVolumeData = weeklyData.map { ChartDataPoint(date: $0.0, value: $0.1) }
    }

    // MARK: - Nutrition Adherence

    private func loadNutritionAdherence(from summaries: [DailyHealthSummary]) {
        let profile = persistence.loadProfile()
        let targets = nutritionCalculator.calculateTargets(profile: profile, historicalData: summaries)
        let meals = persistence.loadMeals(for: nil)

        let calendar = Calendar.current
        var adherencePoints: [ChartDataPoint] = []

        // Group meals by day
        let mealsByDay = Dictionary(grouping: meals) { meal in
            calendar.startOfDay(for: meal.date)
        }

        for summary in summaries.sorted(by: { $0.date < $1.date }) {
            let day = calendar.startOfDay(for: summary.date)
            let dayMeals = mealsByDay[day] ?? []
            let totalCalories = dayMeals.reduce(0.0) { $0 + $1.calories }

            // Adherence = how close to target (100% = perfect)
            let adherence: Double
            if targets.targetCalories > 0 {
                let ratio = totalCalories / targets.targetCalories
                adherence = max(0, 100 - abs(1 - ratio) * 100)
            } else {
                adherence = 0
            }

            adherencePoints.append(ChartDataPoint(date: summary.date, value: adherence))
        }

        nutritionAdherenceData = adherencePoints
    }

    // MARK: - Weight Progress

    private func loadWeightProgress() {
        let entries = persistence.loadWeightHistory()
        let cutoff = Calendar.current.date(byAdding: .day, value: -selectedTimeRange.days, to: Date()) ?? Date()
        let filtered = entries.filter { $0.date >= cutoff }.sorted { $0.date < $1.date }

        weightData = filtered.map { ChartDataPoint(date: $0.date, value: $0.weightKg) }
        weightMovingAverage = computeMovingAverage(filtered.map { ($0.date, $0.weightKg) }, window: 7)
    }

    private func computeMovingAverage(_ entries: [(Date, Double)], window: Int) -> [ChartDataPoint] {
        guard entries.count >= window else { return [] }

        var result: [ChartDataPoint] = []
        for i in (window - 1)..<entries.count {
            let windowSlice = entries[(i - window + 1)...i]
            let avg = windowSlice.reduce(0.0) { $0 + $1.1 } / Double(window)
            result.append(ChartDataPoint(date: entries[i].0, value: avg))
        }
        return result
    }

    // MARK: - Recovery Scores

    private func loadRecoveryScores(from summaries: [DailyHealthSummary]) {
        let analyses = recoveryAnalyzer.analyzeRecoveryTrend(data: summaries)
        recoveryData = analyses.map { ChartDataPoint(date: $0.date, value: Double($0.score)) }
    }

    // MARK: - LLM Recovery Insight

    func generateRecoveryInsight() async {
        guard SubscriptionManager.shared.isPremium else { return }

        isLoadingInsight = true
        recoveryInsight = nil

        let summaries = persistence.loadCachedSummaries()
        let recentSummaries = Array(summaries.sorted { $0.date > $1.date }.prefix(7))
        let meals = persistence.loadMealsForWeek()

        // Build context
        var context = "Last 7 days health data:\n"
        for s in recentSummaries {
            context += "- \(s.date.shortDate): \(Int(s.activeCalories)) active cal, \(Int(s.steps)) steps, "
            context += "\(String(format: "%.1f", s.sleepHours))h sleep, "
            context += "HRV: \(Int(s.hrvMs))ms, RHR: \(Int(s.restingHeartRate))bpm, "
            context += "\(s.workoutCount) workouts (\(Int(s.workoutMinutes)) min)\n"
        }

        let totalMealCalories = meals.reduce(0.0) { $0 + $1.calories }
        let uniqueDays = Set(meals.map { Calendar.current.startOfDay(for: $0.date) }).count
        let dayCount = max(1, min(7, uniqueDays))
        let avgDailyCalories = meals.isEmpty ? 0.0 : totalMealCalories / Double(dayCount)
        let totalProtein = meals.reduce(0.0) { $0 + $1.protein }
        let avgDailyProtein = meals.isEmpty ? 0.0 : totalProtein / Double(dayCount)
        context += "\nAvg daily nutrition: \(Int(avgDailyCalories)) kcal, "
        context += "\(Int(avgDailyProtein))g protein avg/day\n"

        let systemPrompt = """
        You are a sports recovery specialist. Analyze the user's recent health data and provide a brief, \
        actionable recovery insight (3-4 sentences max). Focus on: sleep quality trends, HRV patterns, \
        training load balance, and nutrition adequacy. Be specific and reference their actual numbers. \
        Do not use markdown formatting.
        """

        do {
            let insight = try await llmService.chat(message: context, systemPrompt: systemPrompt)
            recoveryInsight = insight
        } catch {
            recoveryInsight = String(localized: "Unable to generate recovery insight at this time.")
        }

        // Clear conversation to avoid polluting Coach chat
        llmService.clearConversation()

        isLoadingInsight = false
    }

    // MARK: - Summary Stats

    var averageRecoveryScore: Int {
        guard !recoveryData.isEmpty else { return 0 }
        return Int(recoveryData.reduce(0.0) { $0 + $1.value } / Double(recoveryData.count))
    }

    var totalWorkoutMinutes: Int {
        Int(workoutVolumeData.reduce(0.0) { $0 + $1.value })
    }

    var averageNutritionAdherence: Int {
        guard !nutritionAdherenceData.isEmpty else { return 0 }
        return Int(nutritionAdherenceData.reduce(0.0) { $0 + $1.value } / Double(nutritionAdherenceData.count))
    }
}
