import SwiftUI

struct MacroRing: View {
    let protein: Double
    let carbs: Double
    let fat: Double
    let showLabels: Bool
    let size: CGFloat

    init(
        protein: Double,
        carbs: Double,
        fat: Double,
        showLabels: Bool = true,
        size: CGFloat = 120
    ) {
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.showLabels = showLabels
        self.size = size
    }

    private var total: Double {
        protein + carbs + fat
    }

    private var proteinRatio: Double {
        guard total > 0 else { return 0.33 }
        return protein / total
    }

    private var carbsRatio: Double {
        guard total > 0 else { return 0.33 }
        return carbs / total
    }

    private var fatRatio: Double {
        guard total > 0 else { return 0.34 }
        return fat / total
    }

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                // Protein segment
                Circle()
                    .trim(from: 0, to: proteinRatio)
                    .stroke(Color.proteinColor, style: StrokeStyle(lineWidth: size * 0.15, lineCap: .butt))
                    .rotationEffect(.degrees(-90))

                // Carbs segment
                Circle()
                    .trim(from: proteinRatio, to: proteinRatio + carbsRatio)
                    .stroke(Color.carbsColor, style: StrokeStyle(lineWidth: size * 0.15, lineCap: .butt))
                    .rotationEffect(.degrees(-90))

                // Fat segment
                Circle()
                    .trim(from: proteinRatio + carbsRatio, to: 1)
                    .stroke(Color.fatColor, style: StrokeStyle(lineWidth: size * 0.15, lineCap: .butt))
                    .rotationEffect(.degrees(-90))

                // Center label
                VStack(spacing: 2) {
                    Text("\(Int(total))")
                        .font(.system(size: size * 0.2, weight: .bold, design: .rounded))

                    Text("grams")
                        .font(.system(size: size * 0.1))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: size, height: size)

            if showLabels {
                HStack(spacing: 16) {
                    MacroLegendItem(
                        label: "Protein",
                        value: Int(protein),
                        percentage: proteinRatio,
                        color: .proteinColor
                    )

                    MacroLegendItem(
                        label: "Carbs",
                        value: Int(carbs),
                        percentage: carbsRatio,
                        color: .carbsColor
                    )

                    MacroLegendItem(
                        label: "Fat",
                        value: Int(fat),
                        percentage: fatRatio,
                        color: .fatColor
                    )
                }
            }
        }
    }
}

struct MacroLegendItem: View {
    let label: String
    let value: Int
    let percentage: Double
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text("\(value)g")
                .font(.caption.bold())

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text("\(Int(percentage * 100))%")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }
}

// MARK: - Horizontal Macro Bar
struct HorizontalMacroBar: View {
    let protein: Double
    let carbs: Double
    let fat: Double
    let height: CGFloat

    init(protein: Double, carbs: Double, fat: Double, height: CGFloat = 12) {
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.height = height
    }

    private var total: Double {
        protein + carbs + fat
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                if total > 0 {
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(Color.proteinColor)
                        .frame(width: max(geometry.size.width * (protein / total), height))

                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(Color.carbsColor)
                        .frame(width: max(geometry.size.width * (carbs / total), height))

                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(Color.fatColor)
                        .frame(width: max(geometry.size.width * (fat / total), height))
                }
            }
        }
        .frame(height: height)
    }
}

// MARK: - Calorie Breakdown Card
struct CalorieBreakdownCard: View {
    let targets: NutritionTargets

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Daily Targets")
                    .font(.headline)

                Spacer()

                Text("\(Int(targets.targetCalories)) kcal")
                    .font(.title3.bold())
            }

            MacroRing(
                protein: targets.proteinGrams,
                carbs: targets.carbGrams,
                fat: targets.fatGrams,
                size: 140
            )

            Divider()

            VStack(spacing: 8) {
                CalorieBreakdownRow(
                    label: "BMR",
                    value: Int(targets.bmr),
                    description: "Basal metabolic rate"
                )

                CalorieBreakdownRow(
                    label: "TDEE",
                    value: Int(targets.tdee),
                    description: "Total daily expenditure"
                )

                CalorieBreakdownRow(
                    label: "Target",
                    value: Int(targets.targetCalories),
                    description: "\(Int(targets.deficitPercentage * 100))% deficit"
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct CalorieBreakdownRow: View {
    let label: String
    let value: Int
    let description: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline.bold())

                Text(description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(value) kcal")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Macro Target Card
struct MacroTargetCard: View {
    let name: String
    let current: Double
    let target: Double
    let color: Color
    let unit: String

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(current / target, 1.5)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)

                Text(name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(Int(current))/\(Int(target))\(unit)")
                    .font(.subheadline.bold())
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.2))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(progress > 1 ? Color.red : color)
                        .frame(width: geometry.size.width * min(progress, 1.0))
                        .animation(.spring(response: 0.5), value: progress)
                }
            }
            .frame(height: 8)
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 24) {
            MacroRing(
                protein: 150,
                carbs: 200,
                fat: 65
            )

            HorizontalMacroBar(
                protein: 150,
                carbs: 200,
                fat: 65
            )
            .frame(height: 12)
            .padding(.horizontal)

            CalorieBreakdownCard(
                targets: NutritionTargets(
                    bmr: 1800,
                    tdee: 2500,
                    targetCalories: 2100,
                    proteinGrams: 160,
                    fatGrams: 70,
                    carbGrams: 200,
                    deficitPercentage: 0.16,
                    expectedWeeklyLoss: 0.45
                )
            )
        }
        .padding()
    }
}
