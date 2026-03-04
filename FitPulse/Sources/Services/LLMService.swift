import Foundation

// MARK: - Chat Mode
enum ChatMode: String, CaseIterable, Identifiable {
    case mealEstimator = "Meal Estimator"
    case workoutCoach = "Workout Coach"
    case nutritionAdvisor = "Nutrition Advisor"
    case generalQA = "General Q&A"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .mealEstimator: return String(localized: "Meal Estimator")
        case .workoutCoach: return String(localized: "Workout Coach")
        case .nutritionAdvisor: return String(localized: "Nutrition Advisor")
        case .generalQA: return String(localized: "General Q&A")
        }
    }

    var icon: String {
        switch self {
        case .mealEstimator: return "fork.knife"
        case .workoutCoach: return "figure.strengthtraining.traditional"
        case .nutritionAdvisor: return "leaf.fill"
        case .generalQA: return "brain.head.profile"
        }
    }

    var placeholder: String {
        switch self {
        case .mealEstimator: return String(localized: "Describe what you ate...")
        case .workoutCoach: return String(localized: "Ask about exercises, form, programs...")
        case .nutritionAdvisor: return String(localized: "Ask about macros, meal timing, supplements...")
        case .generalQA: return String(localized: "Ask anything about fitness...")
        }
    }

    var quickActions: [(String, String)] {
        switch self {
        case .mealEstimator:
            return [
                (String(localized: "200g chicken breast with rice"), "fork.knife"),
                (String(localized: "Protein shake with banana"), "cup.and.saucer.fill"),
                (String(localized: "Oatmeal with peanut butter and berries"), "leaf.fill"),
            ]
        case .workoutCoach:
            return [
                (String(localized: "What should I train today?"), "calendar"),
                (String(localized: "How do I improve my bench press?"), "figure.strengthtraining.traditional"),
                (String(localized: "Create a PPL split for me"), "list.bullet"),
            ]
        case .nutritionAdvisor:
            return [
                (String(localized: "How much protein do I need?"), "leaf.fill"),
                (String(localized: "What should I eat before training?"), "fork.knife"),
                (String(localized: "Best supplements for muscle growth?"), "pill.fill"),
            ]
        case .generalQA:
            return [
                (String(localized: "How should I structure my workout week?"), "calendar"),
                (String(localized: "I'm feeling overtrained, what should I do?"), "bed.double.fill"),
                (String(localized: "Explain progressive overload"), "chart.line.uptrend.xyaxis"),
            ]
        }
    }

    func systemPrompt(context: ChatContext) -> String {
        switch self {
        case .mealEstimator:
            return Self.mealEstimatorPrompt()
        case .workoutCoach:
            return Self.workoutCoachPrompt(context: context)
        case .nutritionAdvisor:
            return Self.nutritionAdvisorPrompt(context: context)
        case .generalQA:
            return Self.generalQAPrompt(context: context)
        }
    }

    // MARK: - Prompt Builders

    static func mealEstimatorPrompt() -> String {
        """
        You are a nutrition assistant. Estimate calories and macros for foods the user describes. Be concise. Give specific numbers per serving. \(AppLanguage.current.llmInstruction)
        """
    }

    static func workoutCoachPrompt(context: ChatContext) -> String {
        """
        You are a strength coach. Give specific exercise advice with sets, reps, and form cues. User: \(context.userGoal) goal, \(String(format: "%.0f", context.weight))kg.\(context.recentWorkoutSummary.isEmpty ? "" : " Recent: \(context.recentWorkoutSummary)") Be concise. Use bullet points. \(AppLanguage.current.llmInstruction)
        """
    }

    static func nutritionAdvisorPrompt(context: ChatContext) -> String {
        """
        You are a sports nutritionist. Give practical food recommendations with macros. User: \(context.userGoal) goal, \(String(format: "%.0f", context.weight))kg. Be concise. \(AppLanguage.current.llmInstruction)
        """
    }

    static func generalQAPrompt(context: ChatContext) -> String {
        """
        You are a fitness coach and nutritionist. Give concise, actionable advice on training, nutrition, and recovery. User: \(context.userGoal) goal, \(String(format: "%.0f", context.weight))kg.\(context.recentWorkoutSummary.isEmpty ? "" : " Recent: \(context.recentWorkoutSummary)") \(AppLanguage.current.llmInstruction)
        """
    }
}

// MARK: - LLM Service
@MainActor
class LLMService: ObservableObject {
    static let shared = LLMService()

    private init() {}

    // MARK: - Configuration
    var isConfigured: Bool {
        LocalLLMService.shared.isModelLoaded
    }

    var currentModel: String {
        LocalLLMService.shared.loadedModelName ?? "No model loaded"
    }

    // MARK: - Chat Interface
    func chat(message: String, context: ChatContext) async throws -> String {
        let systemPrompt = buildExpertSystemPrompt(context: context)
        return try await chat(message: message, systemPrompt: systemPrompt)
    }

    func chat(message: String, systemPrompt: String, grammar: String? = nil, maxTokens: Int = 512) async throws -> String {
        let localService = LocalLLMService.shared

        guard localService.isModelLoaded else {
            throw LLMError.notConfigured
        }

        return try await localService.generate(prompt: message, systemPrompt: systemPrompt, grammar: grammar, maxTokens: maxTokens)
    }

    func clearConversation() {
        LocalLLMService.shared.clearHistory()
    }

    // MARK: - Expert System Prompt
    private func buildExpertSystemPrompt(context: ChatContext) -> String {
        """
        You are a fitness coach and nutritionist. Give concise, actionable advice on training, nutrition, and recovery. User: \(context.userGoal) goal, \(String(format: "%.0f", context.weight))kg.\(context.recentWorkoutSummary.isEmpty ? "" : " Recent: \(context.recentWorkoutSummary)") Use bullet points. Give specific recommendations (sets, reps, food examples). \(AppLanguage.current.llmInstruction)
        """
    }

    // MARK: - Workout Plan Generation
    func generateWorkoutPlan(for goal: WorkoutGoal, profile: UserProfile, recentWorkouts: [GymWorkout]) async throws -> WorkoutPlan {
        // Clear history — one-shot operation, needs maximum context for generation
        clearConversation()
        defer { clearConversation() }

        let equipmentText = goal.availableEquipment.isEmpty
            ? "all"
            : goal.availableEquipment.map(\.rawValue).joined(separator: ", ")

        let splitText = goal.splitPreference == .letAIDecide
            ? ""
            : " Split: \(goal.splitPreference.rawValue)."

        let systemPrompt = """
        You are a strength coach. Output a JSON workout plan. The "days" array MUST have exactly \(goal.daysPerWeek) entries, one per training day. Each day has 4-6 exercises. /no_think
        """

        let prompt = """
        \(goal.daysPerWeek)-day plan. Goal: \(goal.type.rawValue). Level: \(goal.experienceLevel.rawValue). \(goal.sessionLength)min. Equipment: \(equipmentText).\(splitText)
        """

        let response = try await chat(
            message: prompt,
            systemPrompt: systemPrompt,
            grammar: Self.workoutPlanGrammar,
            maxTokens: 768
        )
        return try parseWorkoutPlan(from: response)
    }

    func suggestNextWorkout(basedOn recentWorkouts: [GymWorkout], profile: UserProfile) async throws -> WorkoutSuggestion {
        // Clear history — one-shot operation
        clearConversation()
        defer { clearConversation() }

        let lastWorkouts = recentWorkouts.prefix(5).map {
            "\($0.date.formatted(date: .abbreviated, time: .omitted)): \($0.name)"
        }.joined(separator: "\n")

        let systemPrompt = """
        You are a strength coach. Suggest today's workout as JSON based on recent training. Consider muscle group rotation and recovery. /no_think
        """

        let prompt = """
        Goal: \(profile.fitnessGoal.rawValue). Recent:\n\(lastWorkouts)
        """

        let response = try await chat(
            message: prompt,
            systemPrompt: systemPrompt,
            grammar: Self.workoutSuggestionGrammar,
            maxTokens: 768
        )
        return try parseWorkoutSuggestion(from: response)
    }

    // MARK: - GBNF Grammar for Food Extraction (Hybrid Pipeline)

    /// GBNF grammar: extracts 1-6 food items with name and quantity from natural language.
    /// The LLM identifies foods; NutritionDatabase provides accurate calorie/macro values.
    private static let foodExtractionGrammar = """
    root    ::= "[" ws item ("," ws item ("," ws item ("," ws item ("," ws item ("," ws item)?)?)?)?)? ws "]"
    item    ::= "{" ws food-kv "," ws qty-kv ws "}"
    food-kv ::= "\\"food\\"" ws ":" ws string
    qty-kv  ::= "\\"qty\\"" ws ":" ws string
    string  ::= "\\"" [^"\\\\]+ "\\""
    ws      ::= " "?
    """

    // MARK: - GBNF Grammar for Workout Plan

    /// GBNF grammar: workout plan with 1-6 days, each with 3-6 exercises. Short strings to save tokens.
    private static let workoutPlanGrammar = """
    root      ::= "{" ws plan-body ws "}"
    plan-body ::= name-kv "," ws desc-kv "," ws days-kv
    name-kv   ::= "\\"name\\"" ws ":" ws string
    desc-kv   ::= "\\"description\\"" ws ":" ws shortstr
    days-kv   ::= "\\"days\\"" ws ":" ws "[" ws day ("," ws day ("," ws day ("," ws day ("," ws day ("," ws day)?)?)?)?)? ws "]"
    day       ::= "{" ws day-name "," ws day-focus "," ws day-exs ws "}"
    day-name  ::= "\\"name\\"" ws ":" ws shortstr
    day-focus ::= "\\"focus\\"" ws ":" ws shortstr
    day-exs   ::= "\\"exercises\\"" ws ":" ws "[" ws exercise "," ws exercise "," ws exercise ("," ws exercise ("," ws exercise ("," ws exercise)?)?)? ws "]"
    exercise  ::= "{" ws ex-name "," ws ex-sets "," ws ex-reps ws "}"
    ex-name   ::= "\\"name\\"" ws ":" ws string
    ex-sets   ::= "\\"sets\\"" ws ":" ws integer
    ex-reps   ::= "\\"reps\\"" ws ":" ws string
    string    ::= "\\"" [^"\\\\]+ "\\""
    shortstr  ::= "\\"" [^"\\\\]{1,40} "\\""
    integer   ::= [0-9]+
    ws        ::= " "?
    """

    // MARK: - GBNF Grammar for Workout Suggestion

    /// GBNF grammar: workout suggestion with 3-6 exercises.
    private static let workoutSuggestionGrammar = """
    root     ::= "{" ws sug-body ws "}"
    sug-body ::= name-kv "," ws focus-kv "," ws exs-kv "," ws dur-kv
    name-kv  ::= "\\"name\\"" ws ":" ws string
    focus-kv ::= "\\"focus\\"" ws ":" ws string
    exs-kv   ::= "\\"exercises\\"" ws ":" ws "[" ws exercise "," ws exercise "," ws exercise ("," ws exercise ("," ws exercise ("," ws exercise)?)?)? ws "]"
    dur-kv   ::= "\\"estimatedDuration\\"" ws ":" ws integer
    exercise ::= "{" ws ex-name "," ws ex-sets "," ws ex-reps ws "}"
    ex-name  ::= "\\"name\\"" ws ":" ws string
    ex-sets  ::= "\\"sets\\"" ws ":" ws integer
    ex-reps  ::= "\\"reps\\"" ws ":" ws string
    string   ::= "\\"" [^"\\\\]+ "\\""
    integer  ::= [0-9]+
    ws       ::= " "?
    """

    // MARK: - Meal Parsing from Natural Language (Hybrid: LLM extraction + DB lookup)

    /// Hybrid pipeline: LLM extracts food names/quantities → NutritionDatabase provides accurate USDA values.
    func parseMealFromDescription(_ description: String) async throws -> LLMParsedMeal {
        // Clear history — one-shot operation, needs maximum context
        clearConversation()
        defer { clearConversation() }

        let systemPrompt = """
        Extract each food from the user's message as JSON. Use the food name in any language. Estimate quantity in grams, ml, or count. Do NOT add foods not mentioned. /no_think
        """

        let response = try await chat(
            message: description,
            systemPrompt: systemPrompt,
            grammar: Self.foodExtractionGrammar
        )

        // Parse LLM extraction: [{food, qty}]
        let jsonString = extractJSON(from: response)
        guard let data = jsonString.data(using: .utf8) else {
            throw LLMError.parsingError
        }

        let extracted = try JSONDecoder().decode([ExtractedFoodItem].self, from: data)
        guard !extracted.isEmpty else {
            throw LLMError.parsingError
        }

        // Look up each food in NutritionDatabase for accurate values
        let db = NutritionDatabase.shared
        var foods: [LLMParsedFood] = []

        for item in extracted {
            // Clean food name: LLM sometimes uses underscores or accented chars
            let cleanedFood = item.food.replacingOccurrences(of: "_", with: " ")
            let entry = db.lookup(cleanedFood)
            let grams = db.parseQuantityToGrams(item.qty, defaultServingG: entry?.defaultServingG)
                ?? entry?.defaultServingG
                ?? 100.0

            let cal: Double
            let pro: Double
            let carb: Double
            let fat: Double
            let name: String
            let serving: String

            if let e = entry {
                // Database hit — use accurate USDA values scaled to serving
                let scale = grams / 100.0
                cal = round(e.caloriesPer100g * scale)
                pro = round(e.proteinPer100g * scale * 10) / 10
                carb = round(e.carbsPer100g * scale * 10) / 10
                fat = round(e.fatPer100g * scale * 10) / 10
                name = e.name
                serving = "\(Int(grams))g"
            } else {
                // Unknown food — show as placeholder for manual edit
                cal = 0
                pro = 0
                carb = 0
                fat = 0
                name = "\(cleanedFood) (edit)"
                serving = item.qty
            }

            foods.append(LLMParsedFood(
                name: name, servingSize: serving,
                calories: cal, protein: pro, carbs: carb, fat: fat
            ))
        }

        // Compute totals
        let totalCal = foods.reduce(0.0) { $0 + $1.calories }
        let totalPro = foods.reduce(0.0) { $0 + $1.protein }
        let totalCarb = foods.reduce(0.0) { $0 + $1.carbs }
        let totalFat = foods.reduce(0.0) { $0 + $1.fat }

        let mealName = foods.count == 1
            ? foods[0].name
            : foods.prefix(3).map { $0.name }.joined(separator: " + ")

        return LLMParsedMeal(
            mealName: mealName,
            foods: foods,
            totalCalories: round(totalCal),
            totalProtein: round(totalPro * 10) / 10,
            totalCarbs: round(totalCarb * 10) / 10,
            totalFat: round(totalFat * 10) / 10
        )
    }

    // MARK: - Response Parsers
    private func parseWorkoutPlan(from response: String) throws -> WorkoutPlan {
        let jsonString = extractJSON(from: response)
        guard let data = jsonString.data(using: .utf8) else {
            throw LLMError.parsingError
        }
        return try JSONDecoder().decode(WorkoutPlan.self, from: data)
    }

    private func parseWorkoutSuggestion(from response: String) throws -> WorkoutSuggestion {
        let jsonString = extractJSON(from: response)
        guard let data = jsonString.data(using: .utf8) else {
            throw LLMError.parsingError
        }
        return try JSONDecoder().decode(WorkoutSuggestion.self, from: data)
    }

    private func extractJSON(from text: String) -> String {
        // Find JSON object or array in response
        if let start = text.firstIndex(of: "{"), let end = text.lastIndex(of: "}") {
            return String(text[start...end])
        }
        if let start = text.firstIndex(of: "["), let end = text.lastIndex(of: "]") {
            return String(text[start...end])
        }
        return text
    }
}

// MARK: - LLM Meal Parsing

struct LLMParsedMeal: Codable {
    let mealName: String
    let foods: [LLMParsedFood]
    let totalCalories: Double
    let totalProtein: Double
    let totalCarbs: Double
    let totalFat: Double
}

struct LLMParsedFood: Codable {
    let name: String
    let servingSize: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
}

/// Intermediate struct for LLM food extraction (hybrid pipeline step 1).
private struct ExtractedFoodItem: Codable {
    let food: String
    let qty: String
}

// MARK: - Supporting Types
struct WorkoutGoal {
    let type: GoalType
    let daysPerWeek: Int
    let sessionLength: Int
    let experienceLevel: ExperienceLevel
    let targetMuscleGroups: [MuscleGroup]
    let availableEquipment: [ExerciseEquipment]
    let splitPreference: SplitPreference
    let additionalNotes: String

    enum GoalType: String, CaseIterable {
        case buildMuscle = "Build Muscle"
        case buildStrength = "Build Strength"
        case loseWeight = "Lose Weight"
        case generalFitness = "General Fitness"
        case athletic = "Athletic Performance"

        var displayName: String {
            switch self {
            case .buildMuscle: return String(localized: "Build Muscle")
            case .buildStrength: return String(localized: "Build Strength")
            case .loseWeight: return String(localized: "Lose Weight")
            case .generalFitness: return String(localized: "General Fitness")
            case .athletic: return String(localized: "Athletic Performance")
            }
        }
    }

    enum ExperienceLevel: String, CaseIterable {
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"

        var displayName: String {
            switch self {
            case .beginner: return String(localized: "Beginner")
            case .intermediate: return String(localized: "Intermediate")
            case .advanced: return String(localized: "Advanced")
            }
        }
    }

    enum SplitPreference: String, CaseIterable {
        case pushPullLegs = "Push/Pull/Legs"
        case upperLower = "Upper/Lower"
        case fullBody = "Full Body"
        case bodyPart = "Body Part Split"
        case letAIDecide = "Let AI Decide"

        var displayName: String {
            switch self {
            case .pushPullLegs: return String(localized: "Push/Pull/Legs")
            case .upperLower: return String(localized: "Upper/Lower")
            case .fullBody: return String(localized: "Full Body")
            case .bodyPart: return String(localized: "Body Part Split")
            case .letAIDecide: return String(localized: "Let AI Decide")
            }
        }
    }
}

struct WorkoutPlan: Codable {
    let name: String
    let description: String
    let days: [WorkoutDay]
    let tips: [String]?
}

struct WorkoutDay: Codable, Identifiable {
    var id: String { name }
    let name: String
    let focus: String
    let exercises: [PlannedExercise]
}

struct PlannedExercise: Codable, Identifiable {
    var id: String { name }
    let name: String
    let sets: Int
    let reps: String
    let notes: String?
}

struct WorkoutSuggestion: Codable {
    let name: String
    let focus: String
    let exercises: [PlannedExercise]
    let estimatedDuration: Int?
}

struct ChatContext {
    let userGoal: String
    let weight: Double
    let recentWorkoutSummary: String
}

enum LLMError: LocalizedError {
    case apiError(String)
    case parsingError
    case notConfigured

    var errorDescription: String? {
        switch self {
        case .apiError(let message): return message
        case .parsingError: return String(localized: "Failed to parse response")
        case .notConfigured: return String(localized: "No model is loaded. Please load a model in Settings.")
        }
    }
}
