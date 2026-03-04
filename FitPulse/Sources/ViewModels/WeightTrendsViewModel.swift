import Foundation
import Combine

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

// MARK: - WeightTrendsViewModel
@MainActor
class WeightTrendsViewModel: ObservableObject {
    @Published var entries: [WeightEntry] = []
    @Published var chartData: [ChartDataPoint] = []
    @Published var movingAverageData: [ChartDataPoint] = []
    @Published var selectedRange: TimeRange = .thirtyDays
    @Published var isLoading = false

    private let healthKitService = HealthKitService.shared
    private let persistence = PersistenceController.shared
    private var profile: UserProfile = PersistenceController.shared.loadProfile()

    // MARK: - Computed Properties

    var currentWeight: Double? {
        entries.last?.weightKg
    }

    var targetWeight: Double? {
        profile.targetWeightKg
    }

    var progressToTarget: Double? {
        guard let target = targetWeight,
              let current = currentWeight,
              let first = entries.first?.weightKg else { return nil }

        let totalChange = abs(first - target)
        guard totalChange > 0 else { return 1.0 }

        let achieved = abs(first - current)
        return min(max(achieved / totalChange, 0), 1.0)
    }

    var weeklyChange: Double? {
        weightChange(overLastDays: 7)
    }

    var monthlyChange: Double? {
        weightChange(overLastDays: 30)
    }

    // MARK: - Data Loading

    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        profile = persistence.loadProfile()

        // Fetch HealthKit weight history (90 days covers all ranges)
        var hkEntries: [WeightEntry] = []
        do {
            hkEntries = try await healthKitService.fetchWeightHistory(days: 90)
        } catch {
            print("Failed to fetch HealthKit weight history: \(error.localizedDescription)")
        }

        // Load manual entries from persistence
        let manualEntries = persistence.loadWeightHistory()

        // Merge by day: HealthKit takes precedence
        entries = mergeEntries(hkEntries: hkEntries, manualEntries: manualEntries)

        recomputeChartData()
    }

    func onRangeChanged() {
        recomputeChartData()
    }

    // MARK: - Moving Average

    func computeMovingAverage(_ entries: [WeightEntry], window: Int) -> [ChartDataPoint] {
        guard entries.count >= window else {
            return entries.map { ChartDataPoint(date: $0.date, value: $0.weightKg) }
        }

        var result: [ChartDataPoint] = []
        for i in (window - 1)..<entries.count {
            let windowSlice = entries[(i - window + 1)...i]
            let avg = windowSlice.reduce(0.0) { $0 + $1.weightKg } / Double(window)
            result.append(ChartDataPoint(date: entries[i].date, value: avg))
        }
        return result
    }

    // MARK: - Private Helpers

    private func mergeEntries(hkEntries: [WeightEntry], manualEntries: [WeightEntry]) -> [WeightEntry] {
        let calendar = Calendar.current

        // Group HK entries by day, keeping the latest per day
        var byDay: [DateComponents: WeightEntry] = [:]

        for entry in hkEntries {
            let comps = calendar.dateComponents([.year, .month, .day], from: entry.date)
            if let existing = byDay[comps] {
                if entry.date > existing.date {
                    byDay[comps] = entry
                }
            } else {
                byDay[comps] = entry
            }
        }

        // Add manual entries only for days not already covered by HK
        for entry in manualEntries {
            let comps = calendar.dateComponents([.year, .month, .day], from: entry.date)
            if byDay[comps] == nil {
                byDay[comps] = entry
            }
        }

        return byDay.values.sorted { $0.date < $1.date }
    }

    private func recomputeChartData() {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -selectedRange.days, to: Date()) ?? Date()

        let filtered = entries.filter { $0.date >= cutoffDate }

        chartData = filtered.map { ChartDataPoint(date: $0.date, value: $0.weightKg) }
        movingAverageData = computeMovingAverage(filtered, window: 7)
    }

    private func weightChange(overLastDays days: Int) -> Double? {
        let calendar = Calendar.current
        let cutoff = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let recent = entries.filter { $0.date >= cutoff }

        guard let first = recent.first?.weightKg,
              let last = recent.last?.weightKg,
              recent.count >= 2 else { return nil }

        return last - first
    }
}
