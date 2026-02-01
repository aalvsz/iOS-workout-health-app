import Foundation
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var todaysPriority: TodaysPriority
    @Published var momentum: MomentumScore
    @Published var caloriesBurned: Int = 0
    @Published var caloriesConsumed: Int = 0
    @Published var hydrationMl: Int = 0
    @Published var hydrationGoal: Int = 2500
    @Published var todayWorkouts: [Workout] = []
    @Published var topInsight: Insight?
    @Published var isLoading = false

    // MARK: - Dependencies
    private let healthService = HealthKitService.shared
    private let nutritionCalculator = NutritionCalculator.shared
    private let hydrationService = HydrationService.shared
    private let persistence = PersistenceController.shared
    private let recoveryAnalyzer = RecoveryAnalyzer.shared

    private var healthUpdateObserver: NSObjectProtocol?

    // MARK: - Computed Properties
    var profile: UserProfile {
        persistence.loadProfile()
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = profile.name.isEmpty ? "" : ", \(profile.name.split(separator: " ").first ?? "")"

        switch hour {
        case 5..<12:
            return "Good morning\(name)"
        case 12..<17:
            return "Good afternoon\(name)"
        case 17..<21:
            return "Good evening\(name)"
        default:
            return "Good night\(name)"
        }
    }

    var profileInitial: String {
        String(profile.name.prefix(1)).uppercased()
    }

    var currentWeight: Double {
        profile.weightKg
    }

    var hydrationText: String {
        let liters = Double(hydrationMl) / 1000
        return String(format: "%.1fL", liters)
    }

    // MARK: - Initialization
    init() {
        // Initialize with defaults
        self.todaysPriority = TodaysPriority(
            type: .nutrition,
            title: "Loading...",
            subtitle: "Getting your data",
            icon: "circle.dotted",
            color: .gray,
            actionText: nil,
            action: nil
        )

        self.momentum = MomentumScore(
            score: 50,
            workoutScore: 0.5,
            nutritionScore: 0.5,
            hydrationScore: 0.5,
            recoveryScore: 0.5
        )

        // Listen for automatic health data updates
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
            // Update with new health data
            if let summary = notification.object as? DailyHealthSummary {
                Task { @MainActor in
                    self?.updateFromHealthData(summary)
                }
            }
        }
    }

    /// Quick update from health data notification (avoids full reload)
    private func updateFromHealthData(_ summary: DailyHealthSummary) {
        // Update calories burned from the new summary
        caloriesBurned = Int(summary.activeCalories)

        // Update today's workouts count from summary
        if summary.workoutCount > todayWorkouts.count {
            // New workout detected - do a full refresh to get workout details
            Task {
                await loadData()
            }
        }
    }

    // MARK: - Data Loading
    func loadData() async {
        isLoading = true

        do {
            // Fetch health data
            let summaries = try await healthService.fetchDailySummaries(days: 7)
            let todaySummary = summaries.first { Calendar.current.isDateInToday($0.date) }
            let workouts = try await healthService.fetchRecentWorkouts(limit: 10)

            // Update calories burned
            caloriesBurned = Int(todaySummary?.activeCalories ?? 0)

            // Get today's workouts
            todayWorkouts = workouts.filter { Calendar.current.isDateInToday($0.date) }

            // Get weekly workout count
            let weekStart = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
            let weeklyWorkouts = workouts.filter { $0.date >= weekStart }

            // Load nutrition data
            let todayMeals = persistence.loadMeals(for: Date())
            caloriesConsumed = Int(todayMeals.reduce(0) { $0 + $1.calories })

            // Load hydration
            hydrationMl = hydrationService.getTodayIntake()
            let hydrationProgress = Double(hydrationMl) / Double(hydrationGoal)

            // Calculate targets
            let targets = nutritionCalculator.calculateTargets(profile: profile, historicalData: summaries)

            // Calculate nutrition adherence
            let nutritionAdherence = min(1.0, Double(caloriesConsumed) / targets.targetCalories)

            // Get recovery score
            let recoveryAnalysis: RecoveryAnalysis?
            if let todaySummary = todaySummary {
                recoveryAnalysis = recoveryAnalyzer.analyzeRecovery(
                    today: todaySummary,
                    historicalData: summaries.suffix(14).map { $0 }
                )
            } else {
                recoveryAnalysis = nil
            }

            // Calculate momentum
            momentum = MomentumScore.calculate(
                weeklyWorkoutsCompleted: weeklyWorkouts.count,
                weeklyWorkoutGoal: profile.weeklyWorkoutGoal,
                nutritionAdherence: nutritionAdherence,
                hydrationProgress: hydrationProgress,
                recoveryScore: recoveryAnalysis?.score
            )

            // Generate today's priority
            todaysPriority = TodaysPriority.generate(
                recoveryScore: recoveryAnalysis?.score,
                todayWorkouts: todayWorkouts.count,
                weeklyWorkoutGoal: profile.weeklyWorkoutGoal,
                weeklyWorkoutsCompleted: weeklyWorkouts.count,
                caloriesConsumed: Double(caloriesConsumed),
                calorieTarget: targets.targetCalories,
                proteinConsumed: todayMeals.reduce(0) { $0 + $1.protein },
                proteinTarget: targets.proteinGrams,
                hydrationProgress: hydrationProgress,
                lastWorkoutDate: workouts.first?.date
            )

            // Generate top insight
            generateTopInsight(
                recoveryAnalysis: recoveryAnalysis,
                weeklyWorkouts: weeklyWorkouts.count,
                nutritionAdherence: nutritionAdherence
            )

        } catch {
            // Use cached/default data on error
            print("Error loading data: \(error)")
        }

        isLoading = false
    }

    func refreshData() async {
        await loadData()
    }

    // MARK: - Actions
    func logWater(amount: Int) {
        hydrationService.logWater(amountMl: amount, source: .water)
        hydrationMl += amount

        // Recalculate priority if hydration was the focus
        if case .hydration = todaysPriority.type {
            Task {
                await loadData()
            }
        }
    }

    func logWeight(_ weight: Double) async {
        // Save to profile
        var profileCopy = profile
        profileCopy.weightKg = weight
        persistence.saveProfile(profileCopy)

        // Save weight entry
        let entry = WeightEntry(date: Date(), weightKg: weight)
        persistence.saveWeightEntry(entry)

        // Refresh data
        await loadData()
    }

    // MARK: - Private Methods
    private func generateTopInsight(
        recoveryAnalysis: RecoveryAnalysis?,
        weeklyWorkouts: Int,
        nutritionAdherence: Double
    ) {
        // Pick the most relevant insight
        if let recovery = recoveryAnalysis, recovery.score < 50 {
            topInsight = Insight(
                title: "Recovery Alert",
                description: recovery.status.recommendation,
                type: .recovery,
                priority: .high
            )
        } else if weeklyWorkouts >= profile.weeklyWorkoutGoal {
            topInsight = Insight(
                title: "Weekly Goal Achieved!",
                description: "You've hit your workout goal. Great consistency!",
                type: .workout,
                priority: .medium
            )
        } else if nutritionAdherence > 0.9 {
            topInsight = Insight(
                title: "Nutrition On Point",
                description: "You're hitting your calorie targets. Keep it up!",
                type: .nutrition,
                priority: .low
            )
        } else {
            topInsight = nil
        }
    }
}
