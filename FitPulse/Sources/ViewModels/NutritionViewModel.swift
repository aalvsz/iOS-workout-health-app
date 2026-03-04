import Foundation
import Combine

@MainActor
class NutritionViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var targets: NutritionTargets?
    @Published var todayMeals: [Meal] = []
    @Published var mealPlan: DayMealPlan?
    @Published var suggestions: [MealSuggestion] = []
    @Published var selectedMealType: Meal.MealType = .breakfast
    @Published var isLoading = false
    @Published var error: String?
    @Published var showingMealLogger = false
    @Published var showingMealSuggestions = false

    // Training-Based Nutrition
    @Published var nutritionTips: [NutritionTip] = []
    @Published var trainingContext: TrainingContext?
    @Published var recentWorkouts: [Workout] = []

    // MARK: - Dependencies
    private let nutritionCalculator = NutritionCalculator.shared
    private let mealPlanner = MealPlannerService.shared
    private let persistence = PersistenceController.shared
    private let healthService = HealthKitService.shared
    private let trainingNutritionService = TrainingNutritionService.shared

    // MARK: - Computed Properties
    var profile: UserProfile {
        persistence.loadProfile()
    }

    var consumedCalories: Double {
        todayMeals.reduce(0) { $0 + $1.calories }
    }

    var consumedProtein: Double {
        todayMeals.reduce(0) { $0 + $1.protein }
    }

    var consumedCarbs: Double {
        todayMeals.reduce(0) { $0 + $1.carbs }
    }

    var consumedFat: Double {
        todayMeals.reduce(0) { $0 + $1.fat }
    }

    var remainingCalories: Double {
        guard let targets = targets else { return 0 }
        return max(0, targets.targetCalories - consumedCalories)
    }

    var calorieProgress: Double {
        guard let targets = targets, targets.targetCalories > 0 else { return 0 }
        return consumedCalories / targets.targetCalories
    }

    var proteinProgress: Double {
        guard let targets = targets, targets.proteinGrams > 0 else { return 0 }
        return consumedProtein / targets.proteinGrams
    }

    var carbsProgress: Double {
        guard let targets = targets, targets.carbGrams > 0 else { return 0 }
        return consumedCarbs / targets.carbGrams
    }

    var fatProgress: Double {
        guard let targets = targets, targets.fatGrams > 0 else { return 0 }
        return consumedFat / targets.fatGrams
    }

    var mealsByType: [Meal.MealType: [Meal]] {
        Dictionary(grouping: todayMeals) { $0.mealType }
    }

    // MARK: - Initialization
    init() {
        loadData()
    }

    // MARK: - Data Loading
    func loadData() {
        calculateTargets()
        loadTodayMeals()
        loadMealPlan()
        generateTrainingBasedTips()
    }

    func refreshData() async {
        isLoading = true

        // Fetch latest health data for adaptive TDEE
        do {
            let summaries = try await healthService.fetchDailySummaries(days: 30)
            targets = nutritionCalculator.calculateTargets(
                profile: profile,
                historicalData: summaries
            )

            // Fetch recent workouts for training context
            recentWorkouts = try await healthService.fetchRecentWorkouts(limit: 5)
        } catch {
            // Fall back to estimated TDEE
            calculateTargets()
        }

        loadTodayMeals()
        generateMealPlan()
        generateTrainingBasedTips()

        isLoading = false
    }

    private func calculateTargets() {
        let cachedSummaries = persistence.loadCachedSummaries()
        targets = nutritionCalculator.calculateTargets(
            profile: profile,
            historicalData: cachedSummaries
        )
    }

    private func loadTodayMeals() {
        todayMeals = persistence.loadMeals(for: Date())
    }

    private func loadMealPlan() {
        if let saved = persistence.loadMealPlan(for: Date()) {
            mealPlan = saved
        } else {
            generateMealPlan()
        }
    }

    // MARK: - Meal Planning
    func generateMealPlan() {
        guard let targets = targets else { return }
        guard SubscriptionManager.shared.canGeneratePlan else { return }

        mealPlan = mealPlanner.generateDayPlan(for: targets)

        if let plan = mealPlan {
            persistence.saveMealPlan(plan)
            SubscriptionManager.shared.recordPlanGeneration()
        }
    }

    func getSuggestionsForMealType(_ type: Meal.MealType) {
        guard let targets = targets else { return }

        selectedMealType = type
        suggestions = mealPlanner.getSuggestions(for: targets, mealType: type)
        showingMealSuggestions = true
    }

    // MARK: - Meal Logging
    func logMeal(_ meal: Meal) {
        persistence.saveMeal(meal)
        loadTodayMeals()
    }

    func deleteMeal(_ meal: Meal) {
        persistence.deleteMeal(meal)
        loadTodayMeals()
    }

    func quickLogMeal(
        name: String,
        type: Meal.MealType,
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double
    ) {
        let meal = Meal(
            name: name,
            mealType: type,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat
        )
        logMeal(meal)
    }

    func logFromSuggestion(_ suggestion: MealSuggestion) {
        let meal = Meal(
            name: suggestion.title,
            mealType: suggestion.mealType,
            calories: Double(suggestion.targetCalories),
            protein: Double(suggestion.targetProtein),
            carbs: Double(suggestion.targetCarbs),
            fat: Double(suggestion.targetFat)
        )
        logMeal(meal)
    }

    // MARK: - Activity-Based Adjustments
    func adjustTargetsForActivity(_ activityCalories: Double) {
        guard let baseTargets = targets else { return }

        // Add back a portion of workout calories
        let adjustment = activityCalories * 0.5

        targets = NutritionTargets(
            bmr: baseTargets.bmr,
            tdee: baseTargets.tdee,
            targetCalories: baseTargets.targetCalories + adjustment,
            proteinGrams: baseTargets.proteinGrams,
            fatGrams: baseTargets.fatGrams,
            carbGrams: baseTargets.carbGrams + (adjustment / 4),
            deficitPercentage: baseTargets.deficitPercentage,
            expectedWeeklyLoss: baseTargets.expectedWeeklyLoss
        )
    }

    // MARK: - Training-Based Tips

    func generateTrainingBasedTips() {
        // Get training context based on today's workouts
        trainingContext = trainingNutritionService.getNutritionContext(
            for: Date(),
            workouts: recentWorkouts
        )

        // Generate tips based on context
        if let context = trainingContext {
            let cachedSummaries = persistence.loadCachedSummaries()
            let todaySummary = cachedSummaries.first {
                Calendar.current.isDate($0.date, inSameDayAs: Date())
            }

            nutritionTips = trainingNutritionService.generateTips(
                context: context,
                todaySummary: todaySummary
            )

            // Adjust targets if needed
            if let baseTargets = targets {
                targets = trainingNutritionService.adjustMacrosForTrainingDay(
                    baseTargets: baseTargets,
                    context: context
                )
            }
        }
    }

    var isInPostWorkoutWindow: Bool {
        if case .postWorkout = trainingContext {
            return true
        }
        return false
    }

    var postWorkoutWindowRemaining: Int? {
        if case .postWorkout(let minutesSince, _) = trainingContext {
            let remaining = 120 - minutesSince
            return remaining > 0 ? remaining : nil
        }
        return nil
    }

    // MARK: - Weekly Progress
    func getWeeklyProgress() -> WeeklyNutritionProgress? {
        guard let targets = targets else { return nil }

        let weekMeals = persistence.loadMealsForWeek()
        let dailyCalories = Dictionary(grouping: weekMeals) { meal in
            Calendar.current.startOfDay(for: meal.date)
        }.mapValues { meals in
            meals.reduce(0.0) { $0 + $1.calories }
        }

        let averageDaily = dailyCalories.values.reduce(0, +) / max(1, Double(dailyCalories.count))
        let daysOnTrack = dailyCalories.values.filter { $0 <= targets.targetCalories * 1.05 }.count

        let weightHistory = persistence.loadWeightHistory()
        let startWeight = weightHistory.first?.weightKg ?? profile.weightKg
        let currentWeight = weightHistory.last?.weightKg ?? profile.weightKg

        return nutritionCalculator.calculateWeeklyProgress(
            weeklyData: persistence.loadCachedSummaries().suffix(7).map { $0 },
            startWeight: startWeight,
            currentWeight: currentWeight,
            targets: targets
        )
    }
}
