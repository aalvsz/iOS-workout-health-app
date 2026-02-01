import Foundation

class MealPlannerService {
    static let shared = MealPlannerService()

    private init() {}

    // MARK: - Meal Suggestions Database
    private let mealDatabase: [MealSuggestion] = [
        // Breakfast Options
        MealSuggestion(
            title: "Protein Power Oatmeal",
            description: "High-protein oatmeal with Greek yogurt, berries, and nut butter for sustained energy.",
            mealType: .breakfast,
            targetCalories: 450,
            targetProtein: 35,
            targetCarbs: 50,
            targetFat: 12,
            foods: [
                SuggestedFood(name: "Oatmeal", amount: "1 cup cooked", calories: 150, protein: 5),
                SuggestedFood(name: "Greek Yogurt", amount: "150g", calories: 130, protein: 20),
                SuggestedFood(name: "Berries", amount: "100g", calories: 50, protein: 1),
                SuggestedFood(name: "Almond Butter", amount: "1 tbsp", calories: 100, protein: 4),
                SuggestedFood(name: "Protein Powder", amount: "1/2 scoop", calories: 50, protein: 10)
            ],
            prepTime: 10,
            tags: ["Quick", "High Protein", "Muscle Building"]
        ),
        MealSuggestion(
            title: "Eggs & Avocado Toast",
            description: "Classic protein-rich breakfast with healthy fats for satiety.",
            mealType: .breakfast,
            targetCalories: 400,
            targetProtein: 25,
            targetCarbs: 30,
            targetFat: 20,
            foods: [
                SuggestedFood(name: "Whole Eggs", amount: "3 large", calories: 210, protein: 18),
                SuggestedFood(name: "Whole Grain Bread", amount: "1 slice", calories: 80, protein: 4),
                SuggestedFood(name: "Avocado", amount: "1/2 medium", calories: 120, protein: 1)
            ],
            prepTime: 15,
            tags: ["Classic", "Keto-Friendly", "Whole Foods"]
        ),
        MealSuggestion(
            title: "Smoothie Bowl",
            description: "Refreshing post-workout breakfast packed with nutrients and protein.",
            mealType: .breakfast,
            targetCalories: 500,
            targetProtein: 40,
            targetCarbs: 55,
            targetFat: 15,
            foods: [
                SuggestedFood(name: "Protein Powder", amount: "1 scoop", calories: 120, protein: 25),
                SuggestedFood(name: "Frozen Berries", amount: "150g", calories: 75, protein: 1),
                SuggestedFood(name: "Banana", amount: "1 medium", calories: 105, protein: 1),
                SuggestedFood(name: "Almond Milk", amount: "200ml", calories: 30, protein: 1),
                SuggestedFood(name: "Granola", amount: "30g", calories: 140, protein: 4),
                SuggestedFood(name: "Chia Seeds", amount: "1 tbsp", calories: 60, protein: 3)
            ],
            prepTime: 5,
            tags: ["Quick", "Post-Workout", "Refreshing"]
        ),

        // Lunch Options
        MealSuggestion(
            title: "Grilled Chicken Salad",
            description: "Lean protein with fresh vegetables and olive oil dressing.",
            mealType: .lunch,
            targetCalories: 550,
            targetProtein: 45,
            targetCarbs: 25,
            targetFat: 28,
            foods: [
                SuggestedFood(name: "Grilled Chicken Breast", amount: "200g", calories: 330, protein: 62),
                SuggestedFood(name: "Mixed Greens", amount: "100g", calories: 20, protein: 2),
                SuggestedFood(name: "Cherry Tomatoes", amount: "100g", calories: 18, protein: 1),
                SuggestedFood(name: "Olive Oil", amount: "1 tbsp", calories: 120, protein: 0),
                SuggestedFood(name: "Feta Cheese", amount: "30g", calories: 75, protein: 4)
            ],
            prepTime: 20,
            tags: ["Low Carb", "High Protein", "Fresh"]
        ),
        MealSuggestion(
            title: "Salmon Rice Bowl",
            description: "Omega-3 rich salmon with brown rice and vegetables.",
            mealType: .lunch,
            targetCalories: 600,
            targetProtein: 40,
            targetCarbs: 50,
            targetFat: 25,
            foods: [
                SuggestedFood(name: "Grilled Salmon", amount: "150g", calories: 280, protein: 35),
                SuggestedFood(name: "Brown Rice", amount: "150g cooked", calories: 165, protein: 4),
                SuggestedFood(name: "Broccoli", amount: "100g", calories: 35, protein: 3),
                SuggestedFood(name: "Edamame", amount: "50g", calories: 60, protein: 6),
                SuggestedFood(name: "Soy Sauce", amount: "1 tbsp", calories: 10, protein: 1)
            ],
            prepTime: 25,
            tags: ["Omega-3", "Balanced", "Asian-Inspired"]
        ),
        MealSuggestion(
            title: "Turkey Wrap",
            description: "Lean turkey with vegetables in a whole wheat wrap.",
            mealType: .lunch,
            targetCalories: 450,
            targetProtein: 35,
            targetCarbs: 40,
            targetFat: 15,
            foods: [
                SuggestedFood(name: "Turkey Breast", amount: "150g", calories: 165, protein: 30),
                SuggestedFood(name: "Whole Wheat Wrap", amount: "1 large", calories: 130, protein: 4),
                SuggestedFood(name: "Hummus", amount: "2 tbsp", calories: 70, protein: 3),
                SuggestedFood(name: "Spinach", amount: "30g", calories: 7, protein: 1),
                SuggestedFood(name: "Bell Peppers", amount: "50g", calories: 15, protein: 0)
            ],
            prepTime: 10,
            tags: ["Quick", "Portable", "Lean Protein"]
        ),

        // Dinner Options
        MealSuggestion(
            title: "Lean Beef Stir-Fry",
            description: "High-protein stir-fry with colorful vegetables and minimal oil.",
            mealType: .dinner,
            targetCalories: 550,
            targetProtein: 45,
            targetCarbs: 35,
            targetFat: 22,
            foods: [
                SuggestedFood(name: "Lean Beef Sirloin", amount: "180g", calories: 280, protein: 45),
                SuggestedFood(name: "Mixed Vegetables", amount: "200g", calories: 80, protein: 4),
                SuggestedFood(name: "Jasmine Rice", amount: "100g cooked", calories: 130, protein: 3),
                SuggestedFood(name: "Sesame Oil", amount: "1 tsp", calories: 40, protein: 0)
            ],
            prepTime: 25,
            tags: ["High Protein", "Quick Cook", "Muscle Building"]
        ),
        MealSuggestion(
            title: "Baked Chicken Thighs",
            description: "Juicy chicken thighs with roasted sweet potato and greens.",
            mealType: .dinner,
            targetCalories: 580,
            targetProtein: 42,
            targetCarbs: 45,
            targetFat: 24,
            foods: [
                SuggestedFood(name: "Chicken Thighs (skinless)", amount: "200g", calories: 260, protein: 38),
                SuggestedFood(name: "Sweet Potato", amount: "200g", calories: 180, protein: 4),
                SuggestedFood(name: "Kale", amount: "100g", calories: 35, protein: 3),
                SuggestedFood(name: "Olive Oil", amount: "1 tbsp", calories: 120, protein: 0)
            ],
            prepTime: 45,
            tags: ["Meal Prep", "Comfort Food", "Balanced"]
        ),
        MealSuggestion(
            title: "Shrimp & Quinoa",
            description: "Light yet protein-packed dinner with complete protein quinoa.",
            mealType: .dinner,
            targetCalories: 480,
            targetProtein: 40,
            targetCarbs: 40,
            targetFat: 16,
            foods: [
                SuggestedFood(name: "Shrimp", amount: "200g", calories: 200, protein: 42),
                SuggestedFood(name: "Quinoa", amount: "150g cooked", calories: 180, protein: 6),
                SuggestedFood(name: "Asparagus", amount: "100g", calories: 20, protein: 2),
                SuggestedFood(name: "Lemon Juice", amount: "1 tbsp", calories: 4, protein: 0),
                SuggestedFood(name: "Garlic", amount: "2 cloves", calories: 10, protein: 0)
            ],
            prepTime: 20,
            tags: ["Light", "Complete Protein", "Mediterranean"]
        ),

        // Snack Options
        MealSuggestion(
            title: "Greek Yogurt Parfait",
            description: "Quick protein boost with probiotics and antioxidants.",
            mealType: .snack,
            targetCalories: 200,
            targetProtein: 20,
            targetCarbs: 20,
            targetFat: 5,
            foods: [
                SuggestedFood(name: "Greek Yogurt", amount: "150g", calories: 130, protein: 20),
                SuggestedFood(name: "Blueberries", amount: "50g", calories: 30, protein: 0),
                SuggestedFood(name: "Honey", amount: "1 tsp", calories: 20, protein: 0)
            ],
            prepTime: 2,
            tags: ["Quick", "Probiotics", "Sweet"]
        ),
        MealSuggestion(
            title: "Protein Shake",
            description: "Fast-absorbing protein for post-workout recovery.",
            mealType: .snack,
            targetCalories: 180,
            targetProtein: 30,
            targetCarbs: 8,
            targetFat: 3,
            foods: [
                SuggestedFood(name: "Whey Protein", amount: "1 scoop", calories: 120, protein: 25),
                SuggestedFood(name: "Banana", amount: "1/2 medium", calories: 50, protein: 0),
                SuggestedFood(name: "Water", amount: "300ml", calories: 0, protein: 0)
            ],
            prepTime: 2,
            tags: ["Post-Workout", "Quick", "Muscle Recovery"]
        ),
        MealSuggestion(
            title: "Nuts & Cottage Cheese",
            description: "Casein protein for sustained amino acid release.",
            mealType: .snack,
            targetCalories: 250,
            targetProtein: 22,
            targetCarbs: 10,
            targetFat: 14,
            foods: [
                SuggestedFood(name: "Cottage Cheese", amount: "150g", calories: 150, protein: 20),
                SuggestedFood(name: "Almonds", amount: "20g", calories: 120, protein: 4)
            ],
            prepTime: 1,
            tags: ["Casein", "Before Bed", "Slow Release"]
        )
    ]

    // MARK: - Post-Workout Meals Database
    private let postWorkoutMeals: [MealSuggestion] = [
        MealSuggestion(
            title: "Recovery Protein Bowl",
            description: "High protein, moderate carbs for optimal post-workout recovery.",
            mealType: .snack,
            targetCalories: 520,
            targetProtein: 45,
            targetCarbs: 50,
            targetFat: 12,
            foods: [
                SuggestedFood(name: "Grilled Chicken", amount: "150g", calories: 250, protein: 35),
                SuggestedFood(name: "White Rice", amount: "150g cooked", calories: 200, protein: 4),
                SuggestedFood(name: "Steamed Vegetables", amount: "100g", calories: 40, protein: 2),
                SuggestedFood(name: "Teriyaki Sauce", amount: "1 tbsp", calories: 30, protein: 0)
            ],
            prepTime: 15,
            tags: ["Post-Workout", "High Protein", "Recovery"]
        ),
        MealSuggestion(
            title: "Chocolate Banana Shake",
            description: "Fast-absorbing carbs and protein for quick recovery.",
            mealType: .snack,
            targetCalories: 380,
            targetProtein: 35,
            targetCarbs: 45,
            targetFat: 8,
            foods: [
                SuggestedFood(name: "Chocolate Whey Protein", amount: "1.5 scoops", calories: 180, protein: 30),
                SuggestedFood(name: "Banana", amount: "1 large", calories: 120, protein: 1),
                SuggestedFood(name: "Almond Milk", amount: "250ml", calories: 40, protein: 1),
                SuggestedFood(name: "Peanut Butter", amount: "1 tbsp", calories: 95, protein: 4)
            ],
            prepTime: 3,
            tags: ["Post-Workout", "Quick", "Shake"]
        ),
        MealSuggestion(
            title: "Rice & Chicken Recovery",
            description: "Classic post-workout combo for muscle repair and glycogen replenishment.",
            mealType: .snack,
            targetCalories: 550,
            targetProtein: 40,
            targetCarbs: 60,
            targetFat: 10,
            foods: [
                SuggestedFood(name: "Grilled Chicken Breast", amount: "150g", calories: 250, protein: 35),
                SuggestedFood(name: "White Rice", amount: "200g cooked", calories: 260, protein: 5),
                SuggestedFood(name: "Broccoli", amount: "80g", calories: 25, protein: 2),
                SuggestedFood(name: "Soy Sauce", amount: "1 tbsp", calories: 10, protein: 1)
            ],
            prepTime: 20,
            tags: ["Post-Workout", "Classic", "Meal Prep"]
        ),
        MealSuggestion(
            title: "Greek Yogurt Protein Bowl",
            description: "Quick protein with fast carbs for recovery window.",
            mealType: .snack,
            targetCalories: 400,
            targetProtein: 35,
            targetCarbs: 45,
            targetFat: 8,
            foods: [
                SuggestedFood(name: "Greek Yogurt", amount: "200g", calories: 170, protein: 20),
                SuggestedFood(name: "Honey", amount: "2 tbsp", calories: 120, protein: 0),
                SuggestedFood(name: "Granola", amount: "40g", calories: 180, protein: 4),
                SuggestedFood(name: "Protein Powder", amount: "1/2 scoop", calories: 60, protein: 12)
            ],
            prepTime: 2,
            tags: ["Post-Workout", "Quick", "Sweet"]
        )
    ]

    // MARK: - Pre-Workout Meals Database
    private let preWorkoutMeals: [MealSuggestion] = [
        MealSuggestion(
            title: "Energy Oats",
            description: "Easy-to-digest carbs for sustained workout energy.",
            mealType: .snack,
            targetCalories: 280,
            targetProtein: 10,
            targetCarbs: 45,
            targetFat: 6,
            foods: [
                SuggestedFood(name: "Oatmeal", amount: "60g dry", calories: 220, protein: 8),
                SuggestedFood(name: "Honey", amount: "1 tbsp", calories: 60, protein: 0),
                SuggestedFood(name: "Cinnamon", amount: "1 tsp", calories: 6, protein: 0)
            ],
            prepTime: 5,
            tags: ["Pre-Workout", "Energy", "Easy Digestion"]
        ),
        MealSuggestion(
            title: "Banana & Peanut Butter Toast",
            description: "Quick energy with a balance of carbs and healthy fats.",
            mealType: .snack,
            targetCalories: 320,
            targetProtein: 10,
            targetCarbs: 40,
            targetFat: 14,
            foods: [
                SuggestedFood(name: "Whole Grain Toast", amount: "1 slice", calories: 80, protein: 3),
                SuggestedFood(name: "Banana", amount: "1 medium", calories: 105, protein: 1),
                SuggestedFood(name: "Peanut Butter", amount: "1.5 tbsp", calories: 140, protein: 6)
            ],
            prepTime: 3,
            tags: ["Pre-Workout", "Quick", "Energy"]
        ),
        MealSuggestion(
            title: "Light Rice Cake Snack",
            description: "Minimal digestion time, quick energy for immediate workout.",
            mealType: .snack,
            targetCalories: 180,
            targetProtein: 4,
            targetCarbs: 35,
            targetFat: 3,
            foods: [
                SuggestedFood(name: "Rice Cakes", amount: "2 cakes", calories: 70, protein: 1),
                SuggestedFood(name: "Honey", amount: "1 tbsp", calories: 60, protein: 0),
                SuggestedFood(name: "Banana", amount: "1/2 medium", calories: 50, protein: 0)
            ],
            prepTime: 1,
            tags: ["Pre-Workout", "Quick", "Light"]
        ),
        MealSuggestion(
            title: "Apple & Almond Butter",
            description: "Natural sugars with a touch of protein for energy.",
            mealType: .snack,
            targetCalories: 250,
            targetProtein: 6,
            targetCarbs: 30,
            targetFat: 12,
            foods: [
                SuggestedFood(name: "Apple", amount: "1 medium", calories: 95, protein: 0),
                SuggestedFood(name: "Almond Butter", amount: "1.5 tbsp", calories: 150, protein: 5)
            ],
            prepTime: 1,
            tags: ["Pre-Workout", "Natural", "Energy"]
        )
    ]

    // MARK: - Meal Suggestions
    func getSuggestions(
        for targets: NutritionTargets,
        mealType: Meal.MealType,
        preferences: MealPreferences = MealPreferences()
    ) -> [MealSuggestion] {
        let mealTargets = calculateMealTargets(from: targets, for: mealType)

        return mealDatabase
            .filter { $0.mealType == mealType }
            .filter { suggestion in
                // Filter by calorie range (within 20%)
                let calorieRange = (Double(mealTargets.calories) * 0.8)...(Double(mealTargets.calories) * 1.2)
                return calorieRange.contains(Double(suggestion.targetCalories))
            }
            .filter { suggestion in
                // Apply dietary preferences
                if preferences.isVegetarian && containsMeat(suggestion) {
                    return false
                }
                if preferences.isLowCarb && suggestion.targetCarbs > 30 {
                    return false
                }
                return true
            }
            .sorted { $0.targetProtein > $1.targetProtein } // Prioritize protein
    }

    func generateDayPlan(for targets: NutritionTargets, preferences: MealPreferences = MealPreferences()) -> DayMealPlan {
        let breakfast = getSuggestions(for: targets, mealType: .breakfast, preferences: preferences).first
        let lunch = getSuggestions(for: targets, mealType: .lunch, preferences: preferences).first
        let dinner = getSuggestions(for: targets, mealType: .dinner, preferences: preferences).first
        let snack = getSuggestions(for: targets, mealType: .snack, preferences: preferences).first

        return DayMealPlan(
            date: Date(),
            breakfast: breakfast,
            lunch: lunch,
            dinner: dinner,
            snacks: snack.map { [$0] } ?? [],
            targets: targets
        )
    }

    // MARK: - Workout-Specific Suggestions

    func getPostWorkoutMeals(caloriesBurned: Double, workoutType: String) -> [MealSuggestion] {
        // Return all post-workout meals, sorted by protein content
        // Higher calorie burns suggest larger recovery meals
        let targetCalories = min(600, max(300, Int(caloriesBurned * 0.8)))

        return postWorkoutMeals
            .sorted { abs($0.targetCalories - targetCalories) < abs($1.targetCalories - targetCalories) }
    }

    func getPreWorkoutMeals(workoutType: String?, timeUntil: Int) -> [MealSuggestion] {
        // For shorter time windows, prefer lighter meals
        if timeUntil < 30 {
            // Very light options only
            return preWorkoutMeals
                .filter { $0.targetCalories < 250 }
                .sorted { $0.prepTime < $1.prepTime }
        } else if timeUntil < 60 {
            // Light to moderate options
            return preWorkoutMeals
                .filter { $0.targetCalories < 350 }
                .sorted { $0.prepTime < $1.prepTime }
        } else {
            // All options available
            return preWorkoutMeals
                .sorted { $0.targetProtein > $1.targetProtein }
        }
    }

    // MARK: - Private Helpers
    private func calculateMealTargets(from targets: NutritionTargets, for mealType: Meal.MealType) -> MealTarget {
        let ratio: Double
        switch mealType {
        case .breakfast:
            ratio = 0.25
        case .lunch:
            ratio = 0.35
        case .dinner:
            ratio = 0.30
        case .snack:
            ratio = 0.10
        }

        return MealTarget(
            mealType: mealType,
            calories: Int(targets.targetCalories * ratio),
            protein: Int(targets.proteinGrams * ratio),
            carbs: Int(targets.carbGrams * ratio),
            fat: Int(targets.fatGrams * ratio)
        )
    }

    private func containsMeat(_ suggestion: MealSuggestion) -> Bool {
        let meatKeywords = ["chicken", "beef", "turkey", "pork", "salmon", "shrimp", "fish"]
        let title = suggestion.title.lowercased()
        let foods = suggestion.foods.map { $0.name.lowercased() }

        return meatKeywords.contains { keyword in
            title.contains(keyword) || foods.contains { $0.contains(keyword) }
        }
    }
}

// MARK: - Supporting Types
struct MealPreferences {
    var isVegetarian: Bool = false
    var isVegan: Bool = false
    var isLowCarb: Bool = false
    var isGlutenFree: Bool = false
    var excludedIngredients: [String] = []
    var preferredPrepTime: Int? = nil // Max prep time in minutes
}

struct DayMealPlan: Identifiable {
    let id = UUID()
    let date: Date
    let breakfast: MealSuggestion?
    let lunch: MealSuggestion?
    let dinner: MealSuggestion?
    let snacks: [MealSuggestion]
    let targets: NutritionTargets

    var totalPlannedCalories: Int {
        [breakfast, lunch, dinner].compactMap { $0?.targetCalories }.reduce(0, +) +
        snacks.reduce(0) { $0 + $1.targetCalories }
    }

    var totalPlannedProtein: Int {
        [breakfast, lunch, dinner].compactMap { $0?.targetProtein }.reduce(0, +) +
        snacks.reduce(0) { $0 + $1.targetProtein }
    }
}
