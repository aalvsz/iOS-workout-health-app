import Foundation
import Combine

@MainActor
class RecoveryViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var todayAnalysis: RecoveryAnalysis?
    @Published var weeklyAnalyses: [RecoveryAnalysis] = []
    @Published var recoveryFlags: [RecoveryFlag] = []
    @Published var insights: [Insight] = []
    @Published var historicalData: [DailyHealthSummary] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var selectedTimeRange: TimeRange = .week

    // MARK: - Dependencies
    private let healthService = HealthKitService.shared
    private let recoveryAnalyzer = RecoveryAnalyzer.shared
    private let persistence = PersistenceController.shared

    // MARK: - Time Range
    enum TimeRange: String, CaseIterable {
        case week = "7 Days"
        case twoWeeks = "14 Days"
        case month = "30 Days"

        var days: Int {
            switch self {
            case .week: return 7
            case .twoWeeks: return 14
            case .month: return 30
            }
        }
    }

    // MARK: - Computed Properties
    var profile: UserProfile {
        persistence.loadProfile()
    }

    var averageRecoveryScore: Double {
        guard !weeklyAnalyses.isEmpty else { return 70 }
        return weeklyAnalyses.reduce(0) { $0 + $1.score } / Double(weeklyAnalyses.count)
    }

    var recoveryTrend: Double {
        guard weeklyAnalyses.count >= 3 else { return 0 }

        let recent = weeklyAnalyses.suffix(3).map(\.score)
        let older = weeklyAnalyses.dropLast(3).suffix(3).map(\.score)

        guard !older.isEmpty else { return 0 }

        let recentAvg = recent.reduce(0, +) / Double(recent.count)
        let olderAvg = older.reduce(0, +) / Double(older.count)

        return ((recentAvg - olderAvg) / olderAvg) * 100
    }

    var currentHRV: Double {
        historicalData.last?.hrvMs ?? 0
    }

    var averageHRV: Double {
        let hrvValues = historicalData.suffix(selectedTimeRange.days).map(\.hrvMs).filter { $0 > 0 }
        guard !hrvValues.isEmpty else { return 0 }
        return hrvValues.reduce(0, +) / Double(hrvValues.count)
    }

    var currentRestingHR: Double {
        historicalData.last?.restingHeartRate ?? 0
    }

    var averageRestingHR: Double {
        let hrValues = historicalData.suffix(selectedTimeRange.days).map(\.restingHeartRate).filter { $0 > 0 }
        guard !hrValues.isEmpty else { return 0 }
        return hrValues.reduce(0, +) / Double(hrValues.count)
    }

    var currentSleep: Double {
        historicalData.last?.sleepHours ?? 0
    }

    var averageSleep: Double {
        let sleepValues = historicalData.suffix(selectedTimeRange.days).map(\.sleepHours).filter { $0 > 0 }
        guard !sleepValues.isEmpty else { return 0 }
        return sleepValues.reduce(0, +) / Double(sleepValues.count)
    }

    var recentFlags: [RecoveryFlag] {
        let cutoff = Date().adding(days: -7)
        return recoveryFlags.filter { $0.date >= cutoff }.sorted { $0.date > $1.date }
    }

    // MARK: - Chart Data
    var recoveryChartData: [ChartDataPoint] {
        weeklyAnalyses.suffix(selectedTimeRange.days).map { analysis in
            ChartDataPoint(date: analysis.date, value: analysis.score)
        }
    }

    var hrvChartData: [ChartDataPoint] {
        historicalData.suffix(selectedTimeRange.days).map { day in
            ChartDataPoint(date: day.date, value: day.hrvMs)
        }
    }

    var sleepChartData: [ChartDataPoint] {
        historicalData.suffix(selectedTimeRange.days).map { day in
            ChartDataPoint(date: day.date, value: day.sleepHours)
        }
    }

    // MARK: - Data Loading
    func loadData() async {
        isLoading = true
        error = nil

        do {
            // Fetch historical health data
            historicalData = try await healthService.fetchDailySummaries(days: 60)

            // Analyze recovery for each day
            analyzeRecovery()

            // Build recovery flags
            recoveryFlags = recoveryAnalyzer.buildRecoveryFlags(data: historicalData)

            // Generate insights
            generateInsights()

        } catch {
            self.error = error.localizedDescription

            // Load cached data as fallback
            historicalData = persistence.loadCachedSummaries()
            if !historicalData.isEmpty {
                analyzeRecovery()
            }
        }

        isLoading = false
    }

    func refreshData() async {
        await loadData()
    }

    // MARK: - Analysis
    private func analyzeRecovery() {
        weeklyAnalyses = recoveryAnalyzer.analyzeRecoveryTrend(data: historicalData)
        todayAnalysis = weeklyAnalyses.last
    }

    private func generateInsights() {
        insights = recoveryAnalyzer.generateInsights(
            analyses: weeklyAnalyses,
            profile: profile
        )
    }

    // MARK: - Time Range
    func setTimeRange(_ range: TimeRange) {
        selectedTimeRange = range
    }

    // MARK: - Recommendations
    var workoutRecommendation: String {
        guard let analysis = todayAnalysis else {
            return "Sync your health data to get personalized recommendations."
        }

        switch analysis.status {
        case .optimal:
            return "Perfect day for high-intensity training or setting PRs!"
        case .good:
            return "You can push yourself today. Consider moderate to high intensity."
        case .moderate:
            return "Moderate intensity is recommended. Listen to your body."
        case .needsRest:
            return "Light activity like walking or stretching is best today."
        case .critical:
            return "Rest day recommended. Focus on recovery."
        }
    }

    var sleepRecommendation: String {
        let deficit = profile.sleepGoalHours - averageSleep

        if deficit > 1 {
            return "You're averaging \(averageSleep.formatted1)h of sleep. Try to get to bed 30 minutes earlier."
        } else if deficit > 0 {
            return "You're close to your sleep goal. A consistent bedtime could help."
        } else {
            return "Great sleep habits! Keep maintaining your \(averageSleep.formatted1)h average."
        }
    }
}
