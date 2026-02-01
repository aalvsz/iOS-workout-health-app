import Foundation

class TrainingNutritionService {
    static let shared = TrainingNutritionService()

    private let mealPlanner = MealPlannerService.shared
    private let healthService = HealthKitService.shared
    private let persistence = PersistenceController.shared

    private init() {}

    // MARK: - Training Context

    func getNutritionContext(for date: Date, workouts: [Workout]) -> TrainingContext {
        let calendar = Calendar.current
        let now = Date()

        // Check for recent workouts (post-workout window)
        if let lastWorkout = workouts.first(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
            let minutesSince = Int(now.timeIntervalSince(lastWorkout.endTime) / 60)
            if minutesSince >= 0 && minutesSince <= 120 {
                return .postWorkout(minutesSince: minutesSince, workout: lastWorkout)
            }
        }

        // Check for upcoming workouts (pre-workout window)
        // This would require scheduled workouts feature - for now we use time-based heuristics
        let hour = calendar.component(.hour, from: now)

        // Morning (6-9am) or afternoon (4-6pm) are common workout times
        if (hour >= 6 && hour <= 9) || (hour >= 16 && hour <= 18) {
            // Assume potential workout in 1-2 hours
            return .preWorkout(minutesUntil: 60)
        }

        // Check workout intensity for today
        let todayWorkouts = workouts.filter { calendar.isDate($0.date, inSameDayAs: date) }

        if todayWorkouts.isEmpty {
            return .restDay
        }

        let totalMinutes = todayWorkouts.reduce(0) { $0 + $1.durationMinutes }
        let totalCalories = todayWorkouts.reduce(0) { $0 + $1.activeCalories }

        if totalMinutes > 60 || totalCalories > 400 {
            return .heavyTrainingDay
        } else {
            return .lightTrainingDay
        }
    }

    // MARK: - Pre-Workout Suggestions

    func getPreWorkoutSuggestions(workout: Workout? = nil, minutesUntil: Int = 60) -> [MealSuggestion] {
        mealPlanner.getPreWorkoutMeals(workoutType: workout?.activityType, timeUntil: minutesUntil)
    }

    // MARK: - Post-Workout Suggestions

    func getPostWorkoutSuggestions(workout: Workout) -> [MealSuggestion] {
        mealPlanner.getPostWorkoutMeals(caloriesBurned: workout.activeCalories, workoutType: workout.activityType)
    }

    // MARK: - Macro Adjustments

    func adjustMacrosForTrainingDay(baseTargets: NutritionTargets, context: TrainingContext) -> NutritionTargets {
        switch context {
        case .restDay:
            // Standard targets on rest days
            return baseTargets

        case .lightTrainingDay:
            // Slight carb increase (+10%)
            let carbIncrease = baseTargets.carbGrams * 0.10
            let calorieIncrease = carbIncrease * 4

            return NutritionTargets(
                bmr: baseTargets.bmr,
                tdee: baseTargets.tdee,
                targetCalories: baseTargets.targetCalories + calorieIncrease,
                proteinGrams: baseTargets.proteinGrams,
                fatGrams: baseTargets.fatGrams,
                carbGrams: baseTargets.carbGrams + carbIncrease,
                deficitPercentage: baseTargets.deficitPercentage,
                expectedWeeklyLoss: baseTargets.expectedWeeklyLoss
            )

        case .heavyTrainingDay:
            // Larger carb increase (+20%)
            let carbIncrease = baseTargets.carbGrams * 0.20
            let calorieIncrease = carbIncrease * 4

            return NutritionTargets(
                bmr: baseTargets.bmr,
                tdee: baseTargets.tdee,
                targetCalories: baseTargets.targetCalories + calorieIncrease,
                proteinGrams: baseTargets.proteinGrams,
                fatGrams: baseTargets.fatGrams,
                carbGrams: baseTargets.carbGrams + carbIncrease,
                deficitPercentage: baseTargets.deficitPercentage,
                expectedWeeklyLoss: baseTargets.expectedWeeklyLoss
            )

        case .preWorkout, .postWorkout:
            // Same as light training day for overall targets
            let carbIncrease = baseTargets.carbGrams * 0.15
            let calorieIncrease = carbIncrease * 4

            return NutritionTargets(
                bmr: baseTargets.bmr,
                tdee: baseTargets.tdee,
                targetCalories: baseTargets.targetCalories + calorieIncrease,
                proteinGrams: baseTargets.proteinGrams,
                fatGrams: baseTargets.fatGrams,
                carbGrams: baseTargets.carbGrams + carbIncrease,
                deficitPercentage: baseTargets.deficitPercentage,
                expectedWeeklyLoss: baseTargets.expectedWeeklyLoss
            )
        }
    }

    // MARK: - Generate Tips

    func generateTips(context: TrainingContext, todaySummary: DailyHealthSummary?) -> [NutritionTip] {
        var tips: [NutritionTip] = []

        switch context {
        case .restDay:
            tips.append(NutritionTip(
                title: "Focus on Recovery",
                description: "Today is a rest day. Prioritize protein and anti-inflammatory foods to support muscle repair.",
                category: .recovery,
                priority: .medium
            ))

            tips.append(NutritionTip(
                title: "Stay Hydrated",
                description: "Even on rest days, proper hydration supports recovery. Aim for your daily water goal.",
                category: .hydration,
                priority: .low
            ))

        case .lightTrainingDay:
            tips.append(NutritionTip(
                title: "Light Training Day",
                description: "Moderate activity today. Maintain regular nutrition with focus on quality protein sources.",
                category: .general,
                priority: .medium
            ))

        case .heavyTrainingDay:
            tips.append(NutritionTip(
                title: "Fuel for Performance",
                description: "Heavy training day! Increase carbs by 15-20% to support energy demands and recovery.",
                category: .general,
                priority: .high
            ))

            tips.append(NutritionTip(
                title: "Extra Hydration Needed",
                description: "Intense workouts increase fluid needs. Add 500ml extra water today.",
                category: .hydration,
                priority: .high
            ))

        case .preWorkout(let minutesUntil):
            let suggestions = getPreWorkoutSuggestions(minutesUntil: minutesUntil)
            tips.append(NutritionTip(
                title: "Pre-Workout Fuel",
                description: "Workout coming up! Have a light, carb-focused snack for sustained energy.",
                category: .preWorkout,
                priority: .high,
                suggestedMeals: suggestions.isEmpty ? nil : Array(suggestions.prefix(3)),
                timing: "Eat \(minutesUntil) min before workout"
            ))

        case .postWorkout(let minutesSince, let workout):
            let suggestions = getPostWorkoutSuggestions(workout: workout)
            let remainingWindow = max(0, 120 - minutesSince)

            tips.append(NutritionTip(
                title: "Recovery Window Active",
                description: "You burned \(Int(workout.activeCalories)) kcal. Eat protein and carbs within 2 hours for optimal recovery.",
                category: .postWorkout,
                priority: .high,
                suggestedMeals: suggestions.isEmpty ? nil : Array(suggestions.prefix(3)),
                timing: remainingWindow > 0 ? "\(remainingWindow) min left in recovery window" : nil
            ))

            tips.append(NutritionTip(
                title: "Rehydrate",
                description: "Replace fluids lost during your \(workout.activityType). Aim for 500ml in the next hour.",
                category: .hydration,
                priority: .high
            ))
        }

        return tips.sorted { $0.priority > $1.priority }
    }

    // MARK: - Post-Workout Window

    func getPostWorkoutWindowRemaining(workout: Workout) -> Int? {
        let minutesSince = Int(Date().timeIntervalSince(workout.endTime) / 60)
        let remaining = 120 - minutesSince

        if remaining > 0 {
            return remaining
        }
        return nil
    }

    func isInPostWorkoutWindow(workouts: [Workout]) -> (Bool, Workout?, Int?) {
        let calendar = Calendar.current
        let now = Date()

        for workout in workouts {
            if calendar.isDate(workout.date, inSameDayAs: now) {
                if let remaining = getPostWorkoutWindowRemaining(workout: workout) {
                    return (true, workout, remaining)
                }
            }
        }

        return (false, nil, nil)
    }
}
