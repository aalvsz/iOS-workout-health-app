import SwiftUI

struct MealCard: View {
    let meal: MealSuggestion
    let onSelect: (() -> Void)?

    init(meal: MealSuggestion, onSelect: (() -> Void)? = nil) {
        self.meal = meal
        self.onSelect = onSelect
    }

    var body: some View {
        Button(action: { onSelect?() }) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: meal.mealType.icon)
                        .font(.title2)
                        .foregroundStyle(.orange)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(meal.title)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text(meal.mealType.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(meal.targetCalories)")
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text("kcal")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Description
                Text(meal.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                // Macros
                HStack(spacing: 16) {
                    MacroLabel(name: "Protein", value: meal.targetProtein, color: .proteinColor)
                    MacroLabel(name: "Carbs", value: meal.targetCarbs, color: .carbsColor)
                    MacroLabel(name: "Fat", value: meal.targetFat, color: .fatColor)

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption)
                        Text("\(meal.prepTime) min")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }

                // Tags
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(meal.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.secondary.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Macro Label
struct MacroLabel: View {
    let name: String
    let value: Int
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)g")
                .font(.subheadline.bold())
                .foregroundStyle(color)

            Text(name)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Compact Meal Row
struct CompactMealRow: View {
    let mealType: Meal.MealType
    let suggestion: MealSuggestion?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: mealType.icon)
                    .font(.title2)
                    .foregroundStyle(.orange)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(mealType.rawValue)
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)

                    if let suggestion = suggestion {
                        Text(suggestion.title)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    } else {
                        Text("Tap to add meal")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer()

                if let suggestion = suggestion {
                    Text("\(suggestion.targetCalories) kcal")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Food Item Row
struct FoodItemRow: View {
    let food: SuggestedFood

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(food.name)
                    .font(.subheadline)

                Text(food.amount)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(food.calories) kcal")
                    .font(.caption.bold())

                Text("\(food.protein)g protein")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Daily Nutrition Summary
struct DailyNutritionSummary: View {
    let consumed: NutritionTargets
    let targets: NutritionTargets

    private var calorieProgress: Double {
        consumed.targetCalories / targets.targetCalories
    }

    var body: some View {
        VStack(spacing: 16) {
            // Calorie ring
            HStack(spacing: 20) {
                ActivityRing(
                    progress: calorieProgress,
                    color: .orange,
                    lineWidth: 15,
                    showLabel: true,
                    label: "Calories"
                )
                .frame(width: 100, height: 100)

                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(Int(consumed.targetCalories))")
                            .font(.title.bold())
                        Text("of \(Int(targets.targetCalories)) kcal")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text("\(Int(targets.targetCalories - consumed.targetCalories)) remaining")
                        .font(.subheadline)
                        .foregroundStyle(calorieProgress < 1 ? .green : .red)
                }

                Spacer()
            }

            // Macro bars
            VStack(spacing: 8) {
                MacroProgressBar(
                    name: "Protein",
                    current: consumed.proteinGrams,
                    target: targets.proteinGrams,
                    color: .proteinColor
                )

                MacroProgressBar(
                    name: "Carbs",
                    current: consumed.carbGrams,
                    target: targets.carbGrams,
                    color: .carbsColor
                )

                MacroProgressBar(
                    name: "Fat",
                    current: consumed.fatGrams,
                    target: targets.fatGrams,
                    color: .fatColor
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Macro Progress Bar
struct MacroProgressBar: View {
    let name: String
    let current: Double
    let target: Double
    let color: Color

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(current / target, 1.0)
    }

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(name)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(Int(current))g / \(Int(target))g")
                    .font(.caption.bold())
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.2))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * progress)
                        .animation(.spring(response: 0.6), value: progress)
                }
            }
            .frame(height: 8)
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            MealCard(
                meal: MealSuggestion(
                    title: "Protein Power Oatmeal",
                    description: "High-protein oatmeal with Greek yogurt, berries, and nut butter for sustained energy.",
                    mealType: .breakfast,
                    targetCalories: 450,
                    targetProtein: 35,
                    targetCarbs: 50,
                    targetFat: 12,
                    foods: [],
                    prepTime: 10,
                    tags: ["Quick", "High Protein", "Muscle Building"]
                )
            )

            CompactMealRow(
                mealType: .lunch,
                suggestion: nil,
                onTap: {}
            )
        }
        .padding()
    }
}
