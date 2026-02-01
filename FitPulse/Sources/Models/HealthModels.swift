import Foundation
import HealthKit

// MARK: - Daily Health Summary
struct DailyHealthSummary: Identifiable, Codable {
    let id: UUID
    let date: Date
    var activeCalories: Double
    var basalCalories: Double
    var steps: Int
    var distanceKm: Double
    var sleepHours: Double
    var hrvMs: Double
    var restingHeartRate: Double
    var workoutCount: Int
    var workoutMinutes: Double
    var workoutCalories: Double

    var totalCalories: Double {
        activeCalories + basalCalories
    }

    var tdee: Double {
        totalCalories
    }

    init(
        id: UUID = UUID(),
        date: Date,
        activeCalories: Double = 0,
        basalCalories: Double = 0,
        steps: Int = 0,
        distanceKm: Double = 0,
        sleepHours: Double = 0,
        hrvMs: Double = 0,
        restingHeartRate: Double = 0,
        workoutCount: Int = 0,
        workoutMinutes: Double = 0,
        workoutCalories: Double = 0
    ) {
        self.id = id
        self.date = date
        self.activeCalories = activeCalories
        self.basalCalories = basalCalories
        self.steps = steps
        self.distanceKm = distanceKm
        self.sleepHours = sleepHours
        self.hrvMs = hrvMs
        self.restingHeartRate = restingHeartRate
        self.workoutCount = workoutCount
        self.workoutMinutes = workoutMinutes
        self.workoutCalories = workoutCalories
    }
}

// MARK: - Workout
struct Workout: Identifiable, Codable {
    let id: UUID
    let date: Date
    let activityType: String
    let activityIcon: String
    let durationMinutes: Double
    let activeCalories: Double
    let distance: Double?
    let averageHeartRate: Double?
    let startTime: Date
    let endTime: Date

    var formattedDuration: String {
        let hours = Int(durationMinutes) / 60
        let minutes = Int(durationMinutes) % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    init(
        id: UUID = UUID(),
        date: Date,
        activityType: String,
        activityIcon: String = "figure.run",
        durationMinutes: Double,
        activeCalories: Double,
        distance: Double? = nil,
        averageHeartRate: Double? = nil,
        startTime: Date,
        endTime: Date
    ) {
        self.id = id
        self.date = date
        self.activityType = activityType
        self.activityIcon = activityIcon
        self.durationMinutes = durationMinutes
        self.activeCalories = activeCalories
        self.distance = distance
        self.averageHeartRate = averageHeartRate
        self.startTime = startTime
        self.endTime = endTime
    }
}

// MARK: - Recovery Status
enum RecoveryStatus: String, Codable, CaseIterable {
    case optimal = "Optimal"
    case good = "Good"
    case moderate = "Moderate"
    case needsRest = "Needs Rest"
    case critical = "Critical"

    var color: String {
        switch self {
        case .optimal: return "recoveryOptimal"
        case .good: return "recoveryGood"
        case .moderate: return "recoveryModerate"
        case .needsRest: return "recoveryNeedsRest"
        case .critical: return "recoveryCritical"
        }
    }

    var icon: String {
        switch self {
        case .optimal: return "battery.100"
        case .good: return "battery.75"
        case .moderate: return "battery.50"
        case .needsRest: return "battery.25"
        case .critical: return "battery.0"
        }
    }

    var recommendation: String {
        switch self {
        case .optimal:
            return "You're fully recovered! Perfect day for high-intensity training."
        case .good:
            return "Good recovery. You can push yourself today with moderate to high intensity."
        case .moderate:
            return "Decent recovery. Consider moderate intensity and listen to your body."
        case .needsRest:
            return "Your body needs rest. Light activity like walking or yoga is recommended."
        case .critical:
            return "Take a rest day. Focus on sleep, nutrition, and stress reduction."
        }
    }
}

// MARK: - Recovery Analysis
struct RecoveryAnalysis: Identifiable, Codable {
    let id: UUID
    let date: Date
    let status: RecoveryStatus
    let score: Double // 0-100
    let hrvDeviation: Double // Z-score
    let heartRateDeviation: Double // Z-score
    let sleepDeviation: Double // Z-score
    let factors: [RecoveryFactor]
    let isAnomaly: Bool
    let anomalyReason: String?

    init(
        id: UUID = UUID(),
        date: Date,
        status: RecoveryStatus,
        score: Double,
        hrvDeviation: Double,
        heartRateDeviation: Double,
        sleepDeviation: Double,
        factors: [RecoveryFactor],
        isAnomaly: Bool = false,
        anomalyReason: String? = nil
    ) {
        self.id = id
        self.date = date
        self.status = status
        self.score = score
        self.hrvDeviation = hrvDeviation
        self.heartRateDeviation = heartRateDeviation
        self.sleepDeviation = sleepDeviation
        self.factors = factors
        self.isAnomaly = isAnomaly
        self.anomalyReason = anomalyReason
    }
}

struct RecoveryFactor: Identifiable, Codable {
    let id: UUID
    let name: String
    let value: Double
    let deviation: Double
    let impact: Impact

    enum Impact: String, Codable {
        case positive
        case neutral
        case negative
    }

    init(id: UUID = UUID(), name: String, value: Double, deviation: Double, impact: Impact) {
        self.id = id
        self.name = name
        self.value = value
        self.deviation = deviation
        self.impact = impact
    }
}

// MARK: - Nutrition Targets
struct NutritionTargets: Codable {
    let bmr: Double
    let tdee: Double
    let targetCalories: Double
    let proteinGrams: Double
    let fatGrams: Double
    let carbGrams: Double
    let deficitPercentage: Double
    let expectedWeeklyLoss: Double // kg

    var proteinPercentage: Double {
        (proteinGrams * 4) / targetCalories * 100
    }

    var fatPercentage: Double {
        (fatGrams * 9) / targetCalories * 100
    }

    var carbPercentage: Double {
        (carbGrams * 4) / targetCalories * 100
    }
}

// MARK: - Meal
struct Meal: Identifiable, Codable {
    let id: UUID
    let name: String
    let mealType: MealType
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let date: Date
    let foods: [Food]

    enum MealType: String, Codable, CaseIterable {
        case breakfast = "Breakfast"
        case lunch = "Lunch"
        case dinner = "Dinner"
        case snack = "Snack"

        var icon: String {
            switch self {
            case .breakfast: return "sun.rise.fill"
            case .lunch: return "sun.max.fill"
            case .dinner: return "moon.stars.fill"
            case .snack: return "leaf.fill"
            }
        }
    }

    init(
        id: UUID = UUID(),
        name: String,
        mealType: MealType,
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        date: Date = Date(),
        foods: [Food] = []
    ) {
        self.id = id
        self.name = name
        self.mealType = mealType
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.date = date
        self.foods = foods
    }
}

struct Food: Identifiable, Codable {
    let id: UUID
    let name: String
    let servingSize: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double

    init(id: UUID = UUID(), name: String, servingSize: String, calories: Double, protein: Double, carbs: Double, fat: Double) {
        self.id = id
        self.name = name
        self.servingSize = servingSize
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
    }
}

// MARK: - Meal Suggestion
struct MealSuggestion: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let mealType: Meal.MealType
    let targetCalories: Int
    let targetProtein: Int
    let targetCarbs: Int
    let targetFat: Int
    let foods: [SuggestedFood]
    let prepTime: Int // minutes
    let tags: [String]

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        mealType: Meal.MealType,
        targetCalories: Int,
        targetProtein: Int,
        targetCarbs: Int,
        targetFat: Int,
        foods: [SuggestedFood],
        prepTime: Int,
        tags: [String]
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.mealType = mealType
        self.targetCalories = targetCalories
        self.targetProtein = targetProtein
        self.targetCarbs = targetCarbs
        self.targetFat = targetFat
        self.foods = foods
        self.prepTime = prepTime
        self.tags = tags
    }
}

struct SuggestedFood: Identifiable, Codable {
    let id: UUID
    let name: String
    let amount: String
    let calories: Int
    let protein: Int

    init(id: UUID = UUID(), name: String, amount: String, calories: Int, protein: Int) {
        self.id = id
        self.name = name
        self.amount = amount
        self.calories = calories
        self.protein = protein
    }
}

// MARK: - Training Context
enum TrainingContext {
    case restDay
    case lightTrainingDay
    case heavyTrainingDay
    case preWorkout(minutesUntil: Int)
    case postWorkout(minutesSince: Int, workout: Workout)

    var title: String {
        switch self {
        case .restDay:
            return "Rest Day"
        case .lightTrainingDay:
            return "Light Training Day"
        case .heavyTrainingDay:
            return "Heavy Training Day"
        case .preWorkout(let minutes):
            return "Pre-Workout (\(minutes) min)"
        case .postWorkout(let minutes, _):
            return "Post-Workout (\(minutes) min ago)"
        }
    }

    var icon: String {
        switch self {
        case .restDay:
            return "bed.double.fill"
        case .lightTrainingDay:
            return "figure.walk"
        case .heavyTrainingDay:
            return "figure.run"
        case .preWorkout:
            return "clock.fill"
        case .postWorkout:
            return "checkmark.circle.fill"
        }
    }

    var nutritionFocus: String {
        switch self {
        case .restDay:
            return "Focus on recovery foods and maintaining protein intake"
        case .lightTrainingDay:
            return "Standard nutrition with moderate carbs"
        case .heavyTrainingDay:
            return "Increase carbs by 10-20% for energy and recovery"
        case .preWorkout:
            return "Light, easy-to-digest carbs for energy"
        case .postWorkout:
            return "High protein and carbs for optimal recovery"
        }
    }
}

// MARK: - Nutrition Tip
struct NutritionTip: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let category: TipCategory
    let priority: TipPriority
    let suggestedMeals: [MealSuggestion]?
    let timing: String?

    enum TipCategory: String, CaseIterable {
        case preWorkout = "Pre-Workout"
        case postWorkout = "Post-Workout"
        case recovery = "Recovery"
        case hydration = "Hydration"
        case general = "General"

        var icon: String {
            switch self {
            case .preWorkout: return "clock.fill"
            case .postWorkout: return "checkmark.circle.fill"
            case .recovery: return "heart.fill"
            case .hydration: return "drop.fill"
            case .general: return "fork.knife"
            }
        }

        var color: String {
            switch self {
            case .preWorkout: return "tipPreWorkout"
            case .postWorkout: return "tipPostWorkout"
            case .recovery: return "tipRecovery"
            case .hydration: return "tipHydration"
            case .general: return "tipGeneral"
            }
        }
    }

    enum TipPriority: Int, Comparable {
        case low = 0
        case medium = 1
        case high = 2

        static func < (lhs: TipPriority, rhs: TipPriority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        category: TipCategory,
        priority: TipPriority = .medium,
        suggestedMeals: [MealSuggestion]? = nil,
        timing: String? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.priority = priority
        self.suggestedMeals = suggestedMeals
        self.timing = timing
    }
}

// MARK: - Insight
struct Insight: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let type: InsightType
    let priority: Priority
    let actionable: Bool
    let action: String?

    enum InsightType {
        case recovery
        case nutrition
        case workout
        case sleep
        case trend
        case anomaly

        var icon: String {
            switch self {
            case .recovery: return "heart.fill"
            case .nutrition: return "fork.knife"
            case .workout: return "figure.run"
            case .sleep: return "bed.double.fill"
            case .trend: return "chart.line.uptrend.xyaxis"
            case .anomaly: return "exclamationmark.triangle.fill"
            }
        }

        var color: String {
            switch self {
            case .recovery: return "recoveryGood"
            case .nutrition: return "nutritionPrimary"
            case .workout: return "workoutPrimary"
            case .sleep: return "sleepPrimary"
            case .trend: return "trendPrimary"
            case .anomaly: return "anomalyWarning"
            }
        }
    }

    enum Priority: Int, Comparable {
        case low = 0
        case medium = 1
        case high = 2
        case critical = 3

        static func < (lhs: Priority, rhs: Priority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        type: InsightType,
        priority: Priority,
        actionable: Bool = false,
        action: String? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.type = type
        self.priority = priority
        self.actionable = actionable
        self.action = action
    }
}

// MARK: - Weekly Summary
struct WeeklySummary: Identifiable {
    let id: UUID
    let weekStartDate: Date
    let totalActiveCalories: Double
    let totalWorkouts: Int
    let totalWorkoutMinutes: Double
    let averageSleep: Double
    let averageHRV: Double
    let averageRecoveryScore: Double
    let totalSteps: Int
    let weightChange: Double?
    let dailySummaries: [DailyHealthSummary]

    var weekEndDate: Date {
        Calendar.current.date(byAdding: .day, value: 6, to: weekStartDate) ?? weekStartDate
    }

    init(
        id: UUID = UUID(),
        weekStartDate: Date,
        totalActiveCalories: Double,
        totalWorkouts: Int,
        totalWorkoutMinutes: Double,
        averageSleep: Double,
        averageHRV: Double,
        averageRecoveryScore: Double,
        totalSteps: Int,
        weightChange: Double? = nil,
        dailySummaries: [DailyHealthSummary]
    ) {
        self.id = id
        self.weekStartDate = weekStartDate
        self.totalActiveCalories = totalActiveCalories
        self.totalWorkouts = totalWorkouts
        self.totalWorkoutMinutes = totalWorkoutMinutes
        self.averageSleep = averageSleep
        self.averageHRV = averageHRV
        self.averageRecoveryScore = averageRecoveryScore
        self.totalSteps = totalSteps
        self.weightChange = weightChange
        self.dailySummaries = dailySummaries
    }
}

// MARK: - Workout Type Mapping
extension HKWorkoutActivityType {
    var displayName: String {
        switch self {
        case .running: return "Running"
        case .cycling: return "Cycling"
        case .walking: return "Walking"
        case .swimming: return "Swimming"
        case .hiking: return "Hiking"
        case .yoga: return "Yoga"
        case .functionalStrengthTraining: return "Strength Training"
        case .traditionalStrengthTraining: return "Weight Training"
        case .highIntensityIntervalTraining: return "HIIT"
        case .crossTraining: return "Cross Training"
        case .elliptical: return "Elliptical"
        case .rowing: return "Rowing"
        case .stairClimbing: return "Stair Climbing"
        case .pilates: return "Pilates"
        case .dance: return "Dance"
        case .coreTraining: return "Core Training"
        case .flexibility: return "Stretching"
        case .cooldown: return "Cooldown"
        case .mixedCardio: return "Cardio"
        default: return "Workout"
        }
    }

    var icon: String {
        switch self {
        case .running: return "figure.run"
        case .cycling: return "figure.outdoor.cycle"
        case .walking: return "figure.walk"
        case .swimming: return "figure.pool.swim"
        case .hiking: return "figure.hiking"
        case .yoga: return "figure.yoga"
        case .functionalStrengthTraining, .traditionalStrengthTraining: return "dumbbell.fill"
        case .highIntensityIntervalTraining: return "flame.fill"
        case .crossTraining: return "figure.cross.training"
        case .elliptical: return "figure.elliptical"
        case .rowing: return "figure.rower"
        case .stairClimbing: return "figure.stairs"
        case .pilates: return "figure.pilates"
        case .dance: return "figure.dance"
        case .coreTraining: return "figure.core.training"
        case .flexibility: return "figure.flexibility"
        case .cooldown: return "figure.cooldown"
        case .mixedCardio: return "heart.fill"
        default: return "figure.mixed.cardio"
        }
    }
}
