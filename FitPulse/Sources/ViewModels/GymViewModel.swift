import Foundation
import Combine

@MainActor
class GymViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var allWorkouts: [GymWorkout] = []
    @Published var currentPlan: WorkoutPlan?
    @Published var nextWorkoutSuggestion: WorkoutSuggestion?
    @Published var insights: [String] = []
    @Published var isLoading = false
    @Published var error: String?

    // MARK: - Dependencies
    private let healthService = HealthKitService.shared
    private let dataParser = HealthDataParser.shared
    private let llmService = LLMService.shared
    private let persistence = PersistenceController.shared

    // MARK: - Computed Properties
    var profile: UserProfile {
        persistence.loadProfile()
    }

    var recentWorkouts: [GymWorkout] {
        allWorkouts.sorted { $0.date > $1.date }
    }

    var thisWeekWorkouts: [GymWorkout] {
        let startOfWeek = Date().startOfWeek
        return allWorkouts.filter { $0.date >= startOfWeek }
    }

    var thisMonthWorkouts: [GymWorkout] {
        let startOfMonth = Date().startOfMonth
        return allWorkouts.filter { $0.date >= startOfMonth }
    }

    var averageWorkoutDuration: Double {
        guard !allWorkouts.isEmpty else { return 0 }
        return allWorkouts.reduce(0) { $0 + $1.duration } / Double(allWorkouts.count)
    }

    var workoutsPerWeek: Double {
        guard let earliest = allWorkouts.last else { return 0 }
        let weeks = max(1, Calendar.current.dateComponents([.weekOfYear], from: earliest.date, to: Date()).weekOfYear ?? 1)
        return Double(allWorkouts.count) / Double(weeks)
    }

    // MARK: - Data Loading
    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        // Load workout history from HealthKit (last 90 days)
        if let ninetyDaysAgo = Calendar.current.date(byAdding: .day, value: -90, to: Date()) {
            do {
                let healthWorkouts = try await healthService.fetchWorkouts(from: ninetyDaysAgo, to: Date())
                allWorkouts = healthWorkouts.map { GymWorkout(from: $0) }
            } catch {
                // HealthKit not authorized or unavailable — continue with empty workouts
                allWorkouts = []
            }
        }

        // Load saved plan
        loadSavedPlan()

        // Generate insights
        generateInsights()

        // Use fallback suggestion instead of LLM call during tab load
        if currentPlan == nil && !recentWorkouts.isEmpty {
            nextWorkoutSuggestion = generateFallbackSuggestion()
        }
    }

    // MARK: - Workout Plan
    func generateWorkoutPlan(goal: WorkoutGoal) async {
        guard SubscriptionManager.shared.canGeneratePlan else {
            self.error = String(localized: "Free limit reached (3/month). Upgrade to Premium for unlimited plans.")
            return
        }

        isLoading = true
        error = nil

        do {
            let plan = try await llmService.generateWorkoutPlan(
                for: goal,
                profile: profile,
                recentWorkouts: recentWorkouts
            )
            currentPlan = plan
            savePlan(plan)
            SubscriptionManager.shared.recordPlanGeneration()
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func previewWorkoutPlan(goal: WorkoutGoal) async throws -> WorkoutPlan {
        guard SubscriptionManager.shared.canGeneratePlan else {
            throw NSError(domain: "FitPulse", code: 1, userInfo: [NSLocalizedDescriptionKey: String(localized: "Free limit reached (3/month). Upgrade to Premium for unlimited plans.")])
        }

        let plan = try await llmService.generateWorkoutPlan(
            for: goal,
            profile: profile,
            recentWorkouts: recentWorkouts
        )
        SubscriptionManager.shared.recordPlanGeneration()
        return plan
    }

    func acceptPlan(_ plan: WorkoutPlan) {
        currentPlan = plan
        savePlan(plan)
    }

    private func savePlan(_ plan: WorkoutPlan) {
        if let data = try? JSONEncoder().encode(plan) {
            UserDefaults.standard.set(data, forKey: "currentWorkoutPlan")
        }
    }

    private func loadSavedPlan() {
        guard let data = UserDefaults.standard.data(forKey: "currentWorkoutPlan"),
              let plan = try? JSONDecoder().decode(WorkoutPlan.self, from: data) else {
            return
        }
        currentPlan = plan
    }

    func clearPlan() {
        currentPlan = nil
        UserDefaults.standard.removeObject(forKey: "currentWorkoutPlan")
    }

    // MARK: - Next Workout Suggestion
    func generateNextWorkoutSuggestion() async {
        guard !recentWorkouts.isEmpty else { return }

        do {
            nextWorkoutSuggestion = try await llmService.suggestNextWorkout(
                basedOn: Array(recentWorkouts.prefix(5)),
                profile: profile
            )
        } catch {
            // Use fallback suggestion
            nextWorkoutSuggestion = generateFallbackSuggestion()
        }
    }

    private func generateFallbackSuggestion() -> WorkoutSuggestion {
        // Determine which muscle group to train based on recent history
        let recentTypes = recentWorkouts.prefix(3).map { $0.name.lowercased() }

        let suggestion: (String, String, [PlannedExercise])

        if recentTypes.contains(where: { $0.contains("push") }) && !recentTypes.contains(where: { $0.contains("pull") }) {
            suggestion = ("Pull Day", "Back, Biceps, Rear Delts", [
                PlannedExercise(name: "Deadlift", sets: 4, reps: "5", notes: "Hip hinge, flat back"),
                PlannedExercise(name: "Barbell Row", sets: 4, reps: "8-10", notes: "Pull to lower chest"),
                PlannedExercise(name: "Pull-ups", sets: 3, reps: "8-12", notes: "Full ROM"),
                PlannedExercise(name: "Face Pulls", sets: 3, reps: "15-20", notes: "External rotation"),
                PlannedExercise(name: "Barbell Curls", sets: 3, reps: "10-12", notes: nil)
            ])
        } else if recentTypes.contains(where: { $0.contains("pull") }) && !recentTypes.contains(where: { $0.contains("leg") }) {
            suggestion = ("Leg Day", "Quads, Hamstrings, Glutes", [
                PlannedExercise(name: "Squat", sets: 4, reps: "6-8", notes: "Below parallel"),
                PlannedExercise(name: "Romanian Deadlift", sets: 3, reps: "10-12", notes: "Feel hamstring stretch"),
                PlannedExercise(name: "Leg Press", sets: 3, reps: "12-15", notes: nil),
                PlannedExercise(name: "Leg Curls", sets: 3, reps: "12-15", notes: nil),
                PlannedExercise(name: "Calf Raises", sets: 4, reps: "15-20", notes: nil)
            ])
        } else {
            suggestion = ("Push Day", "Chest, Shoulders, Triceps", [
                PlannedExercise(name: "Bench Press", sets: 4, reps: "8-10", notes: "Control the negative"),
                PlannedExercise(name: "Overhead Press", sets: 3, reps: "8-10", notes: "Core tight"),
                PlannedExercise(name: "Incline Dumbbell Press", sets: 3, reps: "10-12", notes: nil),
                PlannedExercise(name: "Lateral Raises", sets: 3, reps: "12-15", notes: nil),
                PlannedExercise(name: "Tricep Pushdowns", sets: 3, reps: "12-15", notes: nil)
            ])
        }

        return WorkoutSuggestion(
            name: suggestion.0,
            focus: suggestion.1,
            exercises: suggestion.2,
            estimatedDuration: 60
        )
    }

    // MARK: - Start Workout
    func startWorkout(_ suggestion: WorkoutSuggestion) {
        // In a real app, this would start a workout tracking session
        // For now, just log it
        print("Starting workout: \(suggestion.name)")
    }

    // MARK: - Insights
    private func generateInsights() {
        var newInsights: [String] = []

        // Weekly volume trend
        let lastWeekCount = thisWeekWorkouts.count
        let weekBeforeCount = allWorkouts.filter { workout in
            guard let twoWeeksAgo = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date().startOfWeek) else { return false }
            let oneWeekAgo = Date().startOfWeek
            return workout.date >= twoWeeksAgo && workout.date < oneWeekAgo
        }.count

        if lastWeekCount > weekBeforeCount {
            newInsights.append(String(localized: "Great job! You trained \(lastWeekCount - weekBeforeCount) more times than last week."))
        } else if lastWeekCount < weekBeforeCount {
            newInsights.append(String(localized: "You trained \(weekBeforeCount - lastWeekCount) fewer times than last week. Stay consistent!"))
        }

        // Average duration insight
        if averageWorkoutDuration > 0 {
            newInsights.append(String(localized: "Your average workout is \(Int(averageWorkoutDuration)) minutes. Ideal range is 45-90 minutes."))
        }

        // Consistency insight
        if workoutsPerWeek >= 4 {
            newInsights.append(String(localized: "Excellent consistency! \(String(format: "%.1f", workoutsPerWeek)) workouts per week is great for progress."))
        } else if workoutsPerWeek >= 3 {
            newInsights.append(String(localized: "Good frequency at \(String(format: "%.1f", workoutsPerWeek)) workouts/week. Consider adding one more session."))
        }

        insights = newInsights
    }

    // MARK: - Stats
    func getMonthlyStats() -> MonthlyGymStats {
        let workouts = thisMonthWorkouts
        let totalDuration = workouts.reduce(0) { $0 + $1.duration }
        let totalCalories = workouts.reduce(0) { $0 + $1.calories }

        return MonthlyGymStats(
            totalWorkouts: workouts.count,
            totalDuration: totalDuration,
            totalCalories: totalCalories,
            averageDuration: workouts.isEmpty ? 0 : totalDuration / Double(workouts.count)
        )
    }
}

struct MonthlyGymStats {
    let totalWorkouts: Int
    let totalDuration: Double
    let totalCalories: Double
    let averageDuration: Double
}
