import Foundation

// MARK: - LLM Provider
enum LLMProvider: String, CaseIterable, Codable {
    case native = "On-Device"

    var defaultModel: String {
        return "auto"
    }

    var baseURL: String {
        return ""  // Local inference, no URL needed
    }

    var availableModels: [String] {
        return []  // Dynamic based on imported models
    }

    var description: String {
        return "Runs entirely on your iPhone using Metal GPU. No internet required."
    }

    var requiresAPIKey: Bool {
        return false
    }
}

// MARK: - LLM Service
@MainActor
class LLMService: ObservableObject {
    static let shared = LLMService()

    @Published var isLoading = false
    @Published var error: String?

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
        let localService = LocalLLMService.shared

        guard localService.isModelLoaded else {
            throw LLMError.notConfigured
        }

        return try await localService.generate(prompt: message, systemPrompt: systemPrompt)
    }

    func clearConversation() {
        LocalLLMService.shared.clearHistory()
    }

    // MARK: - Expert System Prompt
    private func buildExpertSystemPrompt(context: ChatContext) -> String {
        """
        You are an elite fitness coach and sports nutritionist with expertise in:

        **Strength Training & Hypertrophy:**
        - Exercise selection, periodization, and programming (5/3/1, PPL, Upper/Lower, Full Body)
        - Proper form and technique cues for all major lifts
        - Progressive overload strategies and deload protocols
        - Muscle group targeting and balanced development
        - Injury prevention and working around limitations

        **Sports Nutrition:**
        - Macro and micronutrient optimization for different goals
        - Meal timing around workouts (pre/intra/post workout nutrition)
        - Caloric calculations for bulking, cutting, and maintenance
        - Supplement recommendations based on scientific evidence
        - Hydration and electrolyte management

        **Recovery & Performance:**
        - Sleep optimization for muscle growth and recovery
        - Active recovery and mobility work
        - Managing training volume and fatigue
        - Signs of overtraining and how to address them

        **USER PROFILE:**
        - Current Goal: \(context.userGoal)
        - Body Weight: \(String(format: "%.1f", context.weight)) kg
        - Recent Training: \(context.recentWorkoutSummary.isEmpty ? "No recent data" : context.recentWorkoutSummary)

        **GUIDELINES:**
        1. Be conversational but informative - explain the "why" behind recommendations
        2. Give specific, actionable advice (exact sets, reps, weights when relevant)
        3. Use scientific evidence but explain it simply
        4. Ask clarifying questions when needed to give better advice
        5. Consider the user's current goal and training history in all responses
        6. For exercises, include form cues and common mistakes to avoid
        7. For nutrition, give practical food examples, not just macros
        8. Be encouraging but realistic about expectations
        9. If something is outside your expertise or potentially dangerous, say so
        10. Format responses for easy reading - use bullet points, numbers when helpful

        You can discuss any fitness or nutrition topic. Be thorough but concise.
        """
    }

    // MARK: - Workout Plan Generation
    func generateWorkoutPlan(for goal: WorkoutGoal, profile: UserProfile, recentWorkouts: [GymWorkout]) async throws -> WorkoutPlan {
        let prompt = """
        Create a detailed \(goal.daysPerWeek)-day workout plan for me.

        My details:
        - Goal: \(goal.type.rawValue)
        - Experience: \(goal.experienceLevel.rawValue)
        - Available days: \(goal.daysPerWeek) per week
        - Session length: \(goal.sessionLength) minutes max

        Please respond with a JSON object in this exact format:
        {
            "name": "Plan Name",
            "description": "Brief description",
            "days": [
                {
                    "name": "Day Name",
                    "focus": "Muscle groups",
                    "exercises": [
                        {"name": "Exercise", "sets": 4, "reps": "8-10", "notes": "Form tip"}
                    ]
                }
            ],
            "tips": ["Tip 1", "Tip 2"]
        }
        """

        let context = ChatContext(
            userGoal: goal.type.rawValue,
            weight: profile.weightKg,
            recentWorkoutSummary: ""
        )

        let response = try await chat(message: prompt, context: context)
        return try parseWorkoutPlan(from: response)
    }

    func suggestNextWorkout(basedOn recentWorkouts: [GymWorkout], profile: UserProfile) async throws -> WorkoutSuggestion {
        let lastWorkouts = recentWorkouts.prefix(5).map {
            "\($0.date.formatted(date: .abbreviated, time: .omitted)): \($0.name)"
        }.joined(separator: "\n")

        let prompt = """
        Based on my recent workouts:
        \(lastWorkouts)

        What should I train today? Consider muscle group rotation and recovery.

        Respond with JSON:
        {
            "name": "Workout Name",
            "focus": "Target muscles",
            "exercises": [{"name": "Exercise", "sets": 4, "reps": "8-10", "notes": "Tip"}],
            "estimatedDuration": 60
        }
        """

        let context = ChatContext(
            userGoal: profile.fitnessGoal.rawValue,
            weight: profile.weightKg,
            recentWorkoutSummary: lastWorkouts
        )

        let response = try await chat(message: prompt, context: context)
        return try parseWorkoutSuggestion(from: response)
    }

    func getMealSuggestions(for targets: NutritionTargets, goal: UserProfile.FitnessGoal) async throws -> [MealSuggestion] {
        let prompt = """
        Suggest 3 meals for today that fit these targets:
        - Calories: \(Int(targets.targetCalories)) kcal
        - Protein: \(Int(targets.proteinGrams))g
        - Goal: \(goal.rawValue)

        Respond with JSON array:
        [{"title": "Meal", "description": "Brief desc", "calories": 500, "protein": 40, "carbs": 50, "fat": 15, "prepTime": 10, "ingredients": ["item1", "item2"]}]
        """

        let context = ChatContext(userGoal: goal.rawValue, weight: 75, recentWorkoutSummary: "")
        let response = try await chat(message: prompt, context: context)
        return try parseMealSuggestions(from: response)
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

    private func parseMealSuggestions(from response: String) throws -> [MealSuggestion] {
        let jsonString = extractJSON(from: response)
        guard let data = jsonString.data(using: .utf8) else {
            throw LLMError.parsingError
        }
        return try JSONDecoder().decode([MealSuggestion].self, from: data)
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

// MARK: - Supporting Types
struct WorkoutGoal {
    let type: GoalType
    let daysPerWeek: Int
    let sessionLength: Int
    let experienceLevel: ExperienceLevel

    enum GoalType: String, CaseIterable {
        case buildMuscle = "Build Muscle"
        case buildStrength = "Build Strength"
        case loseWeight = "Lose Weight"
        case generalFitness = "General Fitness"
        case athletic = "Athletic Performance"
    }

    enum ExperienceLevel: String, CaseIterable {
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
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
        case .parsingError: return "Failed to parse response"
        case .notConfigured: return "Please configure your API key in Profile > AI Settings"
        }
    }
}
