import SwiftUI

struct NutritionView: View {
    var autoShowMealLogger: Bool = false

    @StateObject private var viewModel = NutritionViewModel()
    @State private var showingMealLogger = false
    @State private var selectedMealType: Meal.MealType = .breakfast

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Daily Progress
                    if let targets = viewModel.targets {
                        DailyNutritionCard(
                            consumed: NutritionConsumed(
                                calories: viewModel.consumedCalories,
                                protein: viewModel.consumedProtein,
                                carbs: viewModel.consumedCarbs,
                                fat: viewModel.consumedFat
                            ),
                            targets: targets
                        )
                    }

                    // Training-Based Nutrition Tips
                    if let context = viewModel.trainingContext {
                        TrainingNutritionCard(
                            context: context,
                            tips: viewModel.nutritionTips,
                            postWorkoutWindowRemaining: viewModel.postWorkoutWindowRemaining,
                            onLogMeal: { suggestion in
                                viewModel.logFromSuggestion(suggestion)
                            }
                        )
                    }

                    // Macro Progress Bars
                    if let targets = viewModel.targets {
                        VStack(spacing: 16) {
                            HStack {
                                Text(String(localized: "Macronutrients"))
                                    .font(.headline)
                                Spacer()
                            }

                            MacroTargetCard(
                                name: String(localized: "Protein"),
                                current: viewModel.consumedProtein,
                                target: targets.proteinGrams,
                                color: .proteinColor,
                                unit: String(localized: "g")
                            )

                            MacroTargetCard(
                                name: String(localized: "Carbohydrates"),
                                current: viewModel.consumedCarbs,
                                target: targets.carbGrams,
                                color: .carbsColor,
                                unit: String(localized: "g")
                            )

                            MacroTargetCard(
                                name: String(localized: "Fat"),
                                current: viewModel.consumedFat,
                                target: targets.fatGrams,
                                color: .fatColor,
                                unit: String(localized: "g")
                            )
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    }

                    // Today's Meals
                    VStack(spacing: 16) {
                        HStack {
                            Text(String(localized: "Today's Meals"))
                                .font(.headline)

                            Spacer()

                            Button(action: { showingMealLogger = true }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                            }
                        }

                        ForEach(Meal.MealType.allCases, id: \.self) { mealType in
                            MealSlotCard(
                                mealType: mealType,
                                meals: viewModel.mealsByType[mealType] ?? [],
                                suggestion: suggestionFor(mealType),
                                onAddTap: {
                                    selectedMealType = mealType
                                    viewModel.getSuggestionsForMealType(mealType)
                                }
                            )
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                    // Meal Suggestions
                    if let plan = viewModel.mealPlan {
                        MealPlanCard(plan: plan, onSelect: { suggestion in
                            viewModel.logFromSuggestion(suggestion)
                        })
                    }

                    // Hydration Summary
                    HydrationSummaryCard()

                    // Calorie Breakdown
                    if let targets = viewModel.targets {
                        CalorieBreakdownCard(targets: targets)
                    }
                }
                .padding()
            }
            .navigationTitle(String(localized: "Nutrition"))
            .refreshable {
                await viewModel.refreshData()
            }
            .sheet(isPresented: $showingMealLogger) {
                MealLoggerSheet(
                    mealType: selectedMealType,
                    onLog: { meal in
                        viewModel.logMeal(meal)
                    }
                )
            }
            .onAppear {
                if autoShowMealLogger {
                    showingMealLogger = true
                }
            }
            .sheet(isPresented: $viewModel.showingMealSuggestions) {
                MealSuggestionsSheet(
                    mealType: viewModel.selectedMealType,
                    suggestions: viewModel.suggestions,
                    onSelect: { suggestion in
                        viewModel.logFromSuggestion(suggestion)
                        viewModel.showingMealSuggestions = false
                    }
                )
            }
        }
    }

    private func suggestionFor(_ mealType: Meal.MealType) -> MealSuggestion? {
        switch mealType {
        case .breakfast: return viewModel.mealPlan?.breakfast
        case .lunch: return viewModel.mealPlan?.lunch
        case .dinner: return viewModel.mealPlan?.dinner
        case .snack: return viewModel.mealPlan?.snacks.first
        }
    }
}

// MARK: - Daily Nutrition Card
struct NutritionConsumed {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
}

struct DailyNutritionCard: View {
    let consumed: NutritionConsumed
    let targets: NutritionTargets

    private var calorieProgress: Double {
        consumed.calories / targets.targetCalories
    }

    private var remaining: Double {
        targets.targetCalories - consumed.calories
    }

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text(String(localized: "Today"))
                    .font(.headline)

                Spacer()

                Text(Date().shortDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 24) {
                // Calorie Ring
                ZStack {
                    Circle()
                        .stroke(Color.orange.opacity(0.2), lineWidth: 12)

                    Circle()
                        .trim(from: 0, to: min(calorieProgress, 1))
                        .stroke(
                            calorieProgress > 1 ? Color.red : Color.orange,
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.8), value: calorieProgress)

                    VStack(spacing: 2) {
                        Text("\(Int(consumed.calories))")
                            .font(.title2.bold())

                        Text(String(localized: "kcal"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 100, height: 100)

                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(localized: "Remaining"))
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(String(localized: "\(Int(max(0, remaining))) kcal"))
                            .font(.title3.bold())
                            .foregroundStyle(remaining < 0 ? .red : .primary)
                    }

                    HorizontalMacroBar(
                        protein: consumed.protein,
                        carbs: consumed.carbs,
                        fat: consumed.fat
                    )
                    .frame(height: 10)

                    HStack(spacing: 12) {
                        MacroMiniLabel(value: Int(consumed.protein), unit: String(localized: "g"), label: String(localized: "P"), color: .proteinColor)
                        MacroMiniLabel(value: Int(consumed.carbs), unit: String(localized: "g"), label: String(localized: "C"), color: .carbsColor)
                        MacroMiniLabel(value: Int(consumed.fat), unit: String(localized: "g"), label: String(localized: "F"), color: .fatColor)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct MacroMiniLabel: View {
    let value: Int
    let unit: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 2) {
            Text(label)
                .font(.caption2.bold())
                .foregroundStyle(color)

            Text("\(value)\(unit)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Meal Slot Card
struct MealSlotCard: View {
    let mealType: Meal.MealType
    let meals: [Meal]
    let suggestion: MealSuggestion?
    let onAddTap: () -> Void

    private var totalCalories: Double {
        meals.reduce(0) { $0 + $1.calories }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: mealType.icon)
                    .font(.title2)
                    .foregroundStyle(.orange)
                    .frame(width: 32)

                Text(mealType.rawValue)
                    .font(.headline)

                Spacer()

                if !meals.isEmpty {
                    Text(String(localized: "\(Int(totalCalories)) kcal"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Button(action: onAddTap) {
                    Image(systemName: "plus")
                        .font(.subheadline.bold())
                        .foregroundStyle(.blue)
                }
            }

            if meals.isEmpty {
                if let suggestion = suggestion {
                    HStack {
                        Text(String(localized: "Suggested: \(suggestion.title)"))
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text(String(localized: "\(suggestion.targetCalories) kcal"))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.leading, 40)
                } else {
                    Text(String(localized: "Tap + to log a meal"))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .padding(.leading, 40)
                }
            } else {
                ForEach(meals) { meal in
                    HStack {
                        Text(meal.name)
                            .font(.subheadline)

                        Spacer()

                        Text(String(localized: "\(Int(meal.calories)) kcal"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.leading, 40)
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Meal Plan Card
struct MealPlanCard: View {
    let plan: DayMealPlan
    let onSelect: (MealSuggestion) -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(String(localized: "Suggested Meals"))
                    .font(.headline)

                Spacer()

                Text(String(localized: "\(plan.totalPlannedCalories) kcal total"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let breakfast = plan.breakfast {
                MealSuggestionRow(suggestion: breakfast, onSelect: { onSelect(breakfast) })
            }

            if let lunch = plan.lunch {
                MealSuggestionRow(suggestion: lunch, onSelect: { onSelect(lunch) })
            }

            if let dinner = plan.dinner {
                MealSuggestionRow(suggestion: dinner, onSelect: { onSelect(dinner) })
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct MealSuggestionRow: View {
    let suggestion: MealSuggestion
    let onSelect: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: suggestion.mealType.icon)
                .foregroundStyle(.orange)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(suggestion.title)
                    .font(.subheadline)

                HStack(spacing: 8) {
                    Text(String(localized: "\(suggestion.targetCalories) kcal"))
                    Text(String(localized: "\(suggestion.targetProtein)g protein"))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: onSelect) {
                Text(String(localized: "Log"))
                    .font(.caption.bold())
                    .foregroundStyle(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Meal Logger Sheet
struct MealLoggerSheet: View {
    let mealType: Meal.MealType
    let onLog: (Meal) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var logMode: MealLogMode = .aiEstimate

    // AI Estimate state
    @State private var description = ""
    @State private var isParsingMeal = false
    @State private var parsedMealPreview: LLMParsedMeal?
    @State private var mealParseError: String?
    @State private var selectedMealType: Meal.MealType

    // Manual entry fields
    @State private var name = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""

    enum MealLogMode: CaseIterable {
        case aiEstimate
        case manual

        var displayName: String {
            switch self {
            case .aiEstimate: return String(localized: "AI Estimate")
            case .manual: return String(localized: "Manual")
            }
        }
    }

    init(mealType: Meal.MealType, onLog: @escaping (Meal) -> Void) {
        self.mealType = mealType
        self.onLog = onLog
        self._selectedMealType = State(initialValue: mealType)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker(String(localized: "Mode"), selection: $logMode) {
                    ForEach(MealLogMode.allCases, id: \.self) {
                        Text($0.displayName).tag($0)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                if logMode == .aiEstimate {
                    aiEstimateContent
                } else {
                    manualModeContent
                }
            }
            .navigationTitle(String(localized: "Log Meal"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if logMode == .manual {
                        Button(String(localized: "Save")) { saveManualMeal() }
                            .disabled(name.isEmpty && calories.isEmpty)
                    }
                }
            }
        }
    }

    private var aiEstimateContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "Describe what you ate"))
                        .font(.headline)
                    TextEditor(text: $description)
                        .frame(minHeight: 80)
                        .padding(8)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    Text(String(localized: "Example: \"200g chicken breast with 150g white rice and a mixed salad\""))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                Picker(String(localized: "Meal Type"), selection: $selectedMealType) {
                    ForEach(Meal.MealType.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }
                .pickerStyle(.segmented)

                Button(action: {
                    Task { await parseMeal() }
                }) {
                    HStack {
                        if isParsingMeal {
                            ProgressView()
                                .tint(.white)
                                .padding(.trailing, 4)
                            Text(String(localized: "Analyzing..."))
                        } else {
                            Image(systemName: "sparkles")
                            Text(String(localized: "Analyze with AI"))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(description.isEmpty ? Color.gray : Color.purple)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(description.isEmpty || isParsingMeal)

                if let parsed = parsedMealPreview {
                    LLMMealPreviewCard(parsed: parsed) {
                        confirmParsedMeal(parsed)
                    }
                }

                if let error = mealParseError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Spacer()
            }
            .padding()
        }
    }

    private var manualModeContent: some View {
        Form {
            Section(String(localized: "Meal Details")) {
                TextField(String(localized: "Meal name"), text: $name)
                Picker(String(localized: "Type"), selection: $selectedMealType) {
                    ForEach(Meal.MealType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
            }
            Section(String(localized: "Nutrition")) {
                MacroInputRow(label: String(localized: "Calories"), value: $calories, unit: String(localized: "kcal"))
                MacroInputRow(label: String(localized: "Protein"), value: $protein, unit: String(localized: "g"))
                MacroInputRow(label: String(localized: "Carbs"), value: $carbs, unit: String(localized: "g"))
                MacroInputRow(label: String(localized: "Fat"), value: $fat, unit: String(localized: "g"))
            }
        }
    }

    private func parseMeal() async {
        isParsingMeal = true
        mealParseError = nil
        parsedMealPreview = nil
        do {
            let parsed = try await LLMService.shared.parseMealFromDescription(description)
            parsedMealPreview = parsed
        } catch {
            mealParseError = String(localized: "Could not parse meal. Try being more specific or use manual entry.")
        }
        isParsingMeal = false
    }

    private func confirmParsedMeal(_ parsed: LLMParsedMeal) {
        let foods = parsed.foods.map { f in
            Food(name: f.name, servingSize: f.servingSize,
                 calories: f.calories, protein: f.protein,
                 carbs: f.carbs, fat: f.fat)
        }
        let meal = Meal(
            name: parsed.mealName,
            mealType: selectedMealType,
            calories: parsed.totalCalories,
            protein: parsed.totalProtein,
            carbs: parsed.totalCarbs,
            fat: parsed.totalFat,
            foods: foods
        )
        onLog(meal)

        // Reset for next meal instead of dismissing
        description = ""
        parsedMealPreview = nil
        mealParseError = nil
    }

    private func saveManualMeal() {
        let meal = Meal(
            name: name.isEmpty ? selectedMealType.rawValue : name,
            mealType: selectedMealType,
            calories: Double(calories) ?? 0,
            protein: Double(protein) ?? 0,
            carbs: Double(carbs) ?? 0,
            fat: Double(fat) ?? 0
        )
        onLog(meal)
        dismiss()
    }
}

struct MacroInputRow: View {
    let label: String
    @Binding var value: String
    let unit: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            TextField(String(localized: "0"), text: $value)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
            Text(unit)
                .foregroundStyle(.secondary)
        }
    }
}

struct LLMMealPreviewCard: View {
    let parsed: LLMParsedMeal
    let onConfirm: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(parsed.mealName)
                    .font(.headline)
                Spacer()
                Text(String(localized: "\(Int(parsed.totalCalories)) kcal"))
                    .font(.subheadline.bold())
            }

            ForEach(parsed.foods, id: \.name) { food in
                HStack {
                    Text(food.name)
                        .font(.subheadline)
                    Spacer()
                    Text(food.servingSize)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 16) {
                MacroMiniLabel(value: Int(parsed.totalProtein), unit: String(localized: "g"), label: String(localized: "P"), color: .proteinColor)
                MacroMiniLabel(value: Int(parsed.totalCarbs), unit: String(localized: "g"), label: String(localized: "C"), color: .carbsColor)
                MacroMiniLabel(value: Int(parsed.totalFat), unit: String(localized: "g"), label: String(localized: "F"), color: .fatColor)
            }

            Button(action: onConfirm) {
                Text(String(localized: "Log This Meal"))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Meal Suggestions Sheet
struct MealSuggestionsSheet: View {
    let mealType: Meal.MealType
    let suggestions: [MealSuggestion]
    let onSelect: (MealSuggestion) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(suggestions) { suggestion in
                        MealCard(meal: suggestion) {
                            onSelect(suggestion)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(String(localized: "\(mealType.rawValue) Ideas"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "Done")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Training Nutrition Card
struct TrainingNutritionCard: View {
    let context: TrainingContext
    let tips: [NutritionTip]
    let postWorkoutWindowRemaining: Int?
    let onLogMeal: (MealSuggestion) -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Header with context
            HStack {
                Image(systemName: context.icon)
                    .font(.title2)
                    .foregroundStyle(contextColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(context.title)
                        .font(.headline)

                    Text(context.nutritionFocus)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            // Post-workout window countdown
            if let remaining = postWorkoutWindowRemaining {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(.orange)

                    Text(String(localized: "Recovery window: \(remaining) min left"))
                        .font(.subheadline.bold())
                        .foregroundStyle(.orange)

                    Spacer()
                }
                .padding(10)
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Tips
            ForEach(tips.prefix(2)) { tip in
                TrainingTipRow(tip: tip, onLogMeal: onLogMeal)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var contextColor: Color {
        switch context {
        case .restDay:
            return .blue
        case .lightTrainingDay:
            return .green
        case .heavyTrainingDay:
            return .orange
        case .preWorkout:
            return .yellow
        case .postWorkout:
            return .red
        }
    }
}

struct TrainingTipRow: View {
    let tip: NutritionTip
    let onLogMeal: (MealSuggestion) -> Void

    @State private var showingSuggestions = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: tip.category.icon)
                    .foregroundStyle(categoryColor)
                    .frame(width: 24)

                Text(tip.title)
                    .font(.subheadline.bold())

                Spacer()

                if tip.priority == .high {
                    Text(String(localized: "Important"))
                        .font(.caption2)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange)
                        .clipShape(Capsule())
                }
            }

            Text(tip.description)
                .font(.caption)
                .foregroundStyle(.secondary)

            if let timing = tip.timing {
                HStack {
                    Image(systemName: "clock")
                        .font(.caption)

                    Text(timing)
                        .font(.caption)
                }
                .foregroundStyle(.orange)
            }

            // Suggested meals
            if let meals = tip.suggestedMeals, !meals.isEmpty {
                VStack(spacing: 8) {
                    ForEach(meals.prefix(2)) { meal in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(meal.title)
                                    .font(.caption.bold())

                                Text(String(localized: "\(meal.targetCalories) kcal \u{2022} \(meal.targetProtein)g protein"))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button(action: { onLogMeal(meal) }) {
                                Text(String(localized: "Log"))
                                    .font(.caption.bold())
                                    .foregroundStyle(.blue)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(8)
                        .background(Color.secondary.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var categoryColor: Color {
        switch tip.category {
        case .preWorkout: return .yellow
        case .postWorkout: return .orange
        case .recovery: return .red
        case .hydration: return .blue
        case .general: return .green
        }
    }
}

#Preview {
    NutritionView()
        .environmentObject(UserProfile())
}
