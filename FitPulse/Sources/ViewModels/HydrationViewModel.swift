import Foundation
import Combine

@MainActor
class HydrationViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var todayIntake: Int = 0
    @Published var dailyGoal: HydrationGoal = HydrationGoal(baseMl: 2500)
    @Published var entries: [HydrationEntry] = []
    @Published var hydrationStatus: HydrationStatus = .adequate
    @Published var weeklyProgress: [(date: Date, intake: Int, goal: Int)] = []
    @Published var isLoading = false
    @Published var showingCustomLog = false
    @Published var selectedSource: HydrationSource = .water

    // MARK: - Dependencies
    private let hydrationService = HydrationService.shared
    private let persistence = PersistenceController.shared
    private let healthService = HealthKitService.shared

    // MARK: - Computed Properties
    var profile: UserProfile {
        persistence.loadProfile()
    }

    var progress: Double {
        guard dailyGoal.totalMl > 0 else { return 0 }
        return Double(todayIntake) / Double(dailyGoal.totalMl)
    }

    var remainingMl: Int {
        max(0, dailyGoal.totalMl - todayIntake)
    }

    var remainingLiters: Double {
        Double(remainingMl) / 1000.0
    }

    var todayIntakeLiters: Double {
        Double(todayIntake) / 1000.0
    }

    var goalLiters: Double {
        dailyGoal.totalLiters
    }

    var entriesByHour: [Int: [HydrationEntry]] {
        Dictionary(grouping: entries) { entry in
            Calendar.current.component(.hour, from: entry.date)
        }
    }

    var intakeBySource: [HydrationSource: Int] {
        Dictionary(grouping: entries, by: { $0.source })
            .mapValues { entries in entries.reduce(0) { $0 + $1.amountMl } }
    }

    // MARK: - Initialization
    init() {
        loadData()
    }

    // MARK: - Data Loading
    func loadData() {
        loadTodayData()
        loadWeeklyProgress()
    }

    func refreshData() async {
        isLoading = true

        // Fetch today's activity for goal calculation
        do {
            let summaries = try await healthService.fetchDailySummaries(days: 1)
            if let todaySummary = summaries.first {
                dailyGoal = hydrationService.calculateDailyGoal(
                    profile: profile,
                    todayActivity: todaySummary
                )
            }
        } catch {
            dailyGoal = HydrationGoal.calculate(weightKg: profile.weightKg)
        }

        loadTodayData()
        loadWeeklyProgress()
        isLoading = false
    }

    private func loadTodayData() {
        entries = hydrationService.getTodayEntries()
        todayIntake = entries.reduce(0) { $0 + $1.amountMl }
        dailyGoal = HydrationGoal.calculate(weightKg: profile.weightKg)
        hydrationStatus = HydrationStatus.from(progress: progress)
    }

    private func loadWeeklyProgress() {
        weeklyProgress = hydrationService.getWeeklyProgress(profile: profile)
    }

    // MARK: - Quick Log Methods
    func logGlass(source: HydrationSource = .water) {
        hydrationService.logGlass(source: source)
        loadTodayData()
    }

    func logBottle(source: HydrationSource = .water) {
        hydrationService.logBottle(source: source)
        loadTodayData()
    }

    func logCustom(amountMl: Int, source: HydrationSource = .water) {
        hydrationService.logWater(amountMl: amountMl, source: source)
        loadTodayData()
    }

    func deleteEntry(_ entry: HydrationEntry) {
        hydrationService.deleteEntry(entry)
        loadTodayData()
    }

    // MARK: - Tips
    var currentTip: String {
        hydrationService.getHydrationTip(status: hydrationStatus, remainingMl: remainingMl)
    }

    // MARK: - Formatted Strings
    var progressText: String {
        String(format: "%.1fL / %.1fL", todayIntakeLiters, goalLiters)
    }

    var percentageText: String {
        String(format: "%.0f%%", progress * 100)
    }

    func formatMl(_ ml: Int) -> String {
        if ml >= 1000 {
            return String(format: "%.1fL", Double(ml) / 1000.0)
        }
        return "\(ml)ml"
    }

    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
