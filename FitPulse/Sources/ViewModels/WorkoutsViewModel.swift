import Foundation
import Combine

@MainActor
class WorkoutsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var workouts: [Workout] = []
    @Published var selectedWorkout: Workout?
    @Published var weeklyStats: WeeklyWorkoutStats?
    @Published var monthlyStats: MonthlyWorkoutStats?
    @Published var isLoading = false
    @Published var error: String?
    @Published var selectedTimeRange: TimeRange = .week

    // MARK: - Dependencies
    private let healthService = HealthKitService.shared
    private let persistence = PersistenceController.shared

    // MARK: - Time Range
    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"

        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .year: return 365
            }
        }
    }

    // MARK: - Computed Properties
    var profile: UserProfile {
        persistence.loadProfile()
    }

    var filteredWorkouts: [Workout] {
        let cutoff = Date().adding(days: -selectedTimeRange.days)
        return workouts.filter { $0.date >= cutoff }
    }

    var workoutsByDate: [Date: [Workout]] {
        Dictionary(grouping: filteredWorkouts) { workout in
            Calendar.current.startOfDay(for: workout.date)
        }
    }

    var sortedDates: [Date] {
        workoutsByDate.keys.sorted(by: >)
    }

    var weeklyWorkoutGoalProgress: Double {
        guard let stats = weeklyStats else { return 0 }
        return Double(stats.totalWorkouts) / Double(profile.weeklyWorkoutGoal)
    }

    // MARK: - Data Loading
    func loadWorkouts() async {
        isLoading = true
        error = nil

        do {
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -365, to: endDate)!

            workouts = try await healthService.fetchWorkouts(from: startDate, to: endDate)
            calculateStats()

        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func refreshWorkouts() async {
        await loadWorkouts()
    }

    // MARK: - Stats Calculation
    private func calculateStats() {
        calculateWeeklyStats()
        calculateMonthlyStats()
    }

    private func calculateWeeklyStats() {
        let calendar = Calendar.current
        let startOfWeek = Date().startOfWeek
        let weekWorkouts = workouts.filter { $0.date >= startOfWeek }

        let totalDuration = weekWorkouts.reduce(0.0) { $0 + $1.durationMinutes }
        let totalCalories = weekWorkouts.reduce(0.0) { $0 + $1.activeCalories }

        // Group by type
        var typeBreakdown: [String: Int] = [:]
        for workout in weekWorkouts {
            typeBreakdown[workout.activityType, default: 0] += 1
        }

        // Daily breakdown
        var dailyWorkouts: [Int: Int] = [:]
        for workout in weekWorkouts {
            let weekday = calendar.component(.weekday, from: workout.date)
            dailyWorkouts[weekday, default: 0] += 1
        }

        weeklyStats = WeeklyWorkoutStats(
            totalWorkouts: weekWorkouts.count,
            totalDurationMinutes: totalDuration,
            totalCaloriesBurned: totalCalories,
            averageDuration: weekWorkouts.isEmpty ? 0 : totalDuration / Double(weekWorkouts.count),
            typeBreakdown: typeBreakdown,
            dailyWorkouts: dailyWorkouts
        )
    }

    private func calculateMonthlyStats() {
        let calendar = Calendar.current
        let startOfMonth = Date().startOfMonth
        let monthWorkouts = workouts.filter { $0.date >= startOfMonth }

        let totalDuration = monthWorkouts.reduce(0.0) { $0 + $1.durationMinutes }
        let totalCalories = monthWorkouts.reduce(0.0) { $0 + $1.activeCalories }

        // Weekly breakdown
        var weeklyTotals: [Int: Double] = [:]
        for workout in monthWorkouts {
            let weekOfMonth = calendar.component(.weekOfMonth, from: workout.date)
            weeklyTotals[weekOfMonth, default: 0] += workout.durationMinutes
        }

        monthlyStats = MonthlyWorkoutStats(
            totalWorkouts: monthWorkouts.count,
            totalDurationMinutes: totalDuration,
            totalCaloriesBurned: totalCalories,
            weeklyTotals: weeklyTotals
        )
    }

    // MARK: - Filtering
    func setTimeRange(_ range: TimeRange) {
        selectedTimeRange = range
    }
}

// MARK: - Stats Models
struct WeeklyWorkoutStats {
    let totalWorkouts: Int
    let totalDurationMinutes: Double
    let totalCaloriesBurned: Double
    let averageDuration: Double
    let typeBreakdown: [String: Int]
    let dailyWorkouts: [Int: Int]

    var mostFrequentType: String? {
        typeBreakdown.max(by: { $0.value < $1.value })?.key
    }

    var workoutsPerDay: Double {
        Double(totalWorkouts) / 7.0
    }
}

struct MonthlyWorkoutStats {
    let totalWorkouts: Int
    let totalDurationMinutes: Double
    let totalCaloriesBurned: Double
    let weeklyTotals: [Int: Double]

    var averageWorkoutsPerWeek: Double {
        Double(totalWorkouts) / 4.0
    }
}
