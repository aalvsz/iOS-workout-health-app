import Foundation

class NutritionCalculator {
    static let shared = NutritionCalculator()

    private init() {}

    // MARK: - BMR Calculation (Mifflin-St Jeor Equation)
    func calculateBMR(weightKg: Double, heightCm: Double, age: Int, sex: UserProfile.Sex) -> Double {
        // Mifflin-St Jeor Equation - most accurate for modern populations
        // Men: BMR = 10W + 6.25H - 5A + 5
        // Women: BMR = 10W + 6.25H - 5A - 161
        return 10 * weightKg + 6.25 * heightCm - 5 * Double(age) + sex.bmrConstant
    }

    // MARK: - TDEE Estimation
    func estimateTDEE(bmr: Double, activityLevel: UserProfile.ActivityLevel) -> Double {
        return bmr * activityLevel.multiplier
    }

    func calculateAdaptiveTDEE(historicalData: [DailyHealthSummary], bmr: Double) -> Double {
        // Use actual data if available, otherwise fall back to estimated TDEE
        guard !historicalData.isEmpty else {
            return bmr * 1.55 // Default to moderately active
        }

        // Use 7-day rolling average of actual TDEE
        let recentData = historicalData.suffix(7)
        let averageTDEE = recentData.reduce(0.0) { $0 + $1.tdee } / Double(recentData.count)

        // If data seems unreliable (too high or too low), blend with BMR estimate
        if averageTDEE < bmr || averageTDEE > bmr * 3 {
            return bmr * 1.55
        }

        return averageTDEE
    }

    // MARK: - Nutrition Targets
    func calculateTargets(
        profile: UserProfile,
        historicalData: [DailyHealthSummary] = []
    ) -> NutritionTargets {
        let bmr = calculateBMR(
            weightKg: profile.weightKg,
            heightCm: profile.heightCm,
            age: profile.age,
            sex: profile.sex
        )

        let tdee = historicalData.isEmpty
            ? estimateTDEE(bmr: bmr, activityLevel: profile.activityLevel)
            : calculateAdaptiveTDEE(historicalData: historicalData, bmr: bmr)

        // Calculate target calories based on deficit
        let targetCalories = tdee * (1 - profile.deficitPercentage)

        // Calculate macros
        let proteinGrams = profile.weightKg * profile.proteinPerKg
        let fatGrams = profile.weightKg * profile.fatPerKg

        // Calculate remaining calories for carbs
        let proteinCalories = proteinGrams * 4
        let fatCalories = fatGrams * 9
        let carbCalories = max(0, targetCalories - proteinCalories - fatCalories)
        let carbGrams = carbCalories / 4

        // Expected weekly weight loss (1kg of fat = ~7700 calories)
        let dailyDeficit = tdee - targetCalories
        let weeklyDeficit = dailyDeficit * 7
        let expectedWeeklyLoss = weeklyDeficit / 7700

        return NutritionTargets(
            bmr: bmr,
            tdee: tdee,
            targetCalories: targetCalories,
            proteinGrams: proteinGrams,
            fatGrams: fatGrams,
            carbGrams: carbGrams,
            deficitPercentage: profile.deficitPercentage,
            expectedWeeklyLoss: expectedWeeklyLoss
        )
    }

    // MARK: - Macro Distribution
    func suggestMacroDistribution(for goal: UserProfile.FitnessGoal, weightKg: Double) -> (protein: Double, fat: Double, carbs: Double) {
        let proteinRange = goal.proteinRecommendation
        let proteinPerKg = (proteinRange.lowerBound + proteinRange.upperBound) / 2
        let proteinGrams = weightKg * proteinPerKg

        // Fat: 0.7-1.0 g/kg for most goals
        let fatPerKg: Double
        switch goal {
        case .loseWeight:
            fatPerKg = 0.7
        case .gainMuscle:
            fatPerKg = 1.0
        default:
            fatPerKg = 0.8
        }
        let fatGrams = weightKg * fatPerKg

        // Carbs fill the remaining calories (estimated)
        let estimatedTDEE = 2000.0 // Placeholder
        let remainingCalories = estimatedTDEE - (proteinGrams * 4) - (fatGrams * 9)
        let carbGrams = max(50, remainingCalories / 4)

        return (proteinGrams, fatGrams, carbGrams)
    }

    // MARK: - Meal Distribution
    func distributeMealsForDay(targets: NutritionTargets, mealCount: Int = 3) -> [MealTarget] {
        var meals: [MealTarget] = []

        let mealTypes: [Meal.MealType] = mealCount == 3
            ? [.breakfast, .lunch, .dinner]
            : [.breakfast, .snack, .lunch, .snack, .dinner]

        // Distribute calories: Breakfast 25%, Lunch 35%, Dinner 40%
        let distributions: [Double]
        switch mealCount {
        case 3:
            distributions = [0.25, 0.35, 0.40]
        case 4:
            distributions = [0.20, 0.10, 0.35, 0.35]
        case 5:
            distributions = [0.20, 0.10, 0.30, 0.10, 0.30]
        default:
            distributions = Array(repeating: 1.0 / Double(mealCount), count: mealCount)
        }

        for (index, mealType) in mealTypes.prefix(mealCount).enumerated() {
            let ratio = distributions[index]
            meals.append(MealTarget(
                mealType: mealType,
                calories: Int(targets.targetCalories * ratio),
                protein: Int(targets.proteinGrams * ratio),
                carbs: Int(targets.carbGrams * ratio),
                fat: Int(targets.fatGrams * ratio)
            ))
        }

        return meals
    }

    // MARK: - Calorie Adjustment
    func adjustCaloriesForActivity(baseTargets: NutritionTargets, todayActivity: DailyHealthSummary) -> NutritionTargets {
        // If significantly more active than usual, add back some calories
        let activityBonus = max(0, todayActivity.workoutCalories * 0.3) // Add back 30% of workout calories

        return NutritionTargets(
            bmr: baseTargets.bmr,
            tdee: baseTargets.tdee + activityBonus,
            targetCalories: baseTargets.targetCalories + activityBonus,
            proteinGrams: baseTargets.proteinGrams,
            fatGrams: baseTargets.fatGrams,
            carbGrams: baseTargets.carbGrams + (activityBonus / 4), // Add carbs for workout recovery
            deficitPercentage: baseTargets.deficitPercentage,
            expectedWeeklyLoss: baseTargets.expectedWeeklyLoss
        )
    }
}

// MARK: - Meal Target
struct MealTarget: Identifiable {
    let id = UUID()
    let mealType: Meal.MealType
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
}

// MARK: - Progress Tracking
extension NutritionCalculator {
    func calculateWeeklyProgress(
        weeklyData: [DailyHealthSummary],
        startWeight: Double,
        currentWeight: Double,
        targets: NutritionTargets
    ) -> WeeklyNutritionProgress {
        let actualDeficit = weeklyData.reduce(0.0) { total, day in
            let deficit = targets.tdee - day.totalCalories
            return total + deficit
        }

        let weightChange = startWeight - currentWeight
        let targetWeightChange = targets.expectedWeeklyLoss

        let progressPercentage = targetWeightChange > 0
            ? min(1.0, weightChange / targetWeightChange)
            : 1.0

        return WeeklyNutritionProgress(
            actualDeficit: actualDeficit,
            targetDeficit: (targets.tdee - targets.targetCalories) * 7,
            weightChange: weightChange,
            targetWeightChange: targetWeightChange,
            progressPercentage: progressPercentage,
            averageDailyCalories: weeklyData.reduce(0.0) { $0 + $1.totalCalories } / max(1, Double(weeklyData.count)),
            daysOnTrack: weeklyData.filter { $0.totalCalories <= targets.targetCalories * 1.05 }.count
        )
    }
}

struct WeeklyNutritionProgress {
    let actualDeficit: Double
    let targetDeficit: Double
    let weightChange: Double
    let targetWeightChange: Double
    let progressPercentage: Double
    let averageDailyCalories: Double
    let daysOnTrack: Int

    var isOnTrack: Bool {
        progressPercentage >= 0.8
    }

    var feedback: String {
        if progressPercentage >= 1.0 {
            return "Excellent progress! You're exceeding your goals."
        } else if progressPercentage >= 0.8 {
            return "Great job! You're on track with your nutrition."
        } else if progressPercentage >= 0.5 {
            return "Good effort. Consider adjusting portion sizes or increasing activity."
        } else {
            return "Let's refocus. Small consistent changes lead to big results."
        }
    }
}
