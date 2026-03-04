import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var showingWeightInput = false
    @State private var newWeight = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Recovery Card
                    if let recovery = viewModel.recoveryAnalysis {
                        RecoveryHeroCard(analysis: recovery)
                    }

                    // Quick Stats Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        if let today = viewModel.todaySummary {
                            MetricCard(
                                title: String(localized: "Steps"),
                                value: today.steps.formattedSteps,
                                subtitle: String(localized: "Goal: \(viewModel.profile.dailyStepsGoal.formattedSteps)"),
                                icon: "figure.walk",
                                iconColor: .green,
                                trend: nil
                            )

                            MetricCard(
                                title: String(localized: "Active Calories"),
                                value: "\(Int(today.activeCalories))",
                                subtitle: String(localized: "kcal burned"),
                                icon: "flame.fill",
                                iconColor: .orange
                            )

                            MetricCard(
                                title: String(localized: "Sleep"),
                                value: today.sleepHours.formattedHours,
                                subtitle: String(localized: "Goal: \(viewModel.profile.sleepGoalHours.formatted0)h"),
                                icon: "bed.double.fill",
                                iconColor: .indigo
                            )

                            MetricCard(
                                title: String(localized: "Workouts"),
                                value: "\(viewModel.weeklyWorkoutCount)/\(viewModel.profile.weeklyWorkoutGoal)",
                                subtitle: String(localized: "This week"),
                                icon: "figure.run",
                                iconColor: .blue
                            )
                        }
                    }

                    // Activity Rings
                    if let today = viewModel.todaySummary {
                        ActivitySummaryCard(
                            summary: today,
                            profile: viewModel.profile
                        )
                    }

                    // Hydration Quick View
                    HydrationQuickCard()

                    // Nutrition Quick View
                    if let targets = viewModel.nutritionTargets {
                        NutritionQuickCard(targets: targets)
                    }

                    // Recent Workouts
                    if !viewModel.recentWorkouts.isEmpty {
                        RecentWorkoutsCard(workouts: viewModel.recentWorkouts)
                    }

                    // Insights
                    if !viewModel.insights.isEmpty {
                        InsightsCard(insights: viewModel.insights)
                    }
                }
                .padding()
            }
            .navigationTitle(String(localized: "FitPulse"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingWeightInput = true }) {
                        Image(systemName: "scalemass.fill")
                    }
                }
            }
            .refreshable {
                await viewModel.refreshData()
            }
            .task {
                await viewModel.loadData()
            }
            .sheet(isPresented: $showingWeightInput) {
                WeightInputSheet(
                    currentWeight: viewModel.profile.weightKg,
                    onSave: { weight in
                        Task {
                            await viewModel.logWeight(weight)
                        }
                    }
                )
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.ultraThinMaterial)
                }
            }
        }
    }
}

// MARK: - Recovery Hero Card
struct RecoveryHeroCard: View {
    let analysis: RecoveryAnalysis

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "Today's Recovery"))
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(Int(analysis.score))")
                            .font(.system(size: 48, weight: .bold, design: .rounded))

                        Text(String(localized: "/100"))
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }

                    RecoveryBadge(score: analysis.score, status: analysis.status)
                }

                Spacer()

                RecoveryIndicator(
                    score: analysis.score,
                    status: analysis.status,
                    showDetails: false
                )
                .frame(width: 100, height: 100)
            }

            Text(analysis.status.recommendation)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if analysis.isAnomaly, let reason = analysis.anomalyReason {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)

                    Text(String(localized: "Unusual: \(reason)"))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()
                }
                .padding(10)
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Activity Summary Card
struct ActivitySummaryCard: View {
    let summary: DailyHealthSummary
    let profile: UserProfile

    private var stepsProgress: Double {
        Double(summary.steps) / Double(profile.dailyStepsGoal)
    }

    private var caloriesProgress: Double {
        summary.activeCalories / 500 // Assume 500 active cal goal
    }

    private var sleepProgress: Double {
        summary.sleepHours / profile.sleepGoalHours
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(String(localized: "Today's Activity"))
                    .font(.headline)

                Spacer()

                Text(Date().dayOfWeek)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 24) {
                TripleActivityRings(
                    moveProgress: min(caloriesProgress, 1.5),
                    exerciseProgress: min(Double(summary.workoutMinutes) / 30, 1.5),
                    standProgress: stepsProgress,
                    size: 120
                )

                VStack(alignment: .leading, spacing: 12) {
                    ActivityLegendRow(
                        color: .caloriesRing,
                        label: String(localized: "Move"),
                        value: String(localized: "\(Int(summary.activeCalories)) kcal"),
                        progress: caloriesProgress
                    )

                    ActivityLegendRow(
                        color: .exerciseRing,
                        label: String(localized: "Exercise"),
                        value: String(localized: "\(Int(summary.workoutMinutes)) min"),
                        progress: Double(summary.workoutMinutes) / 30
                    )

                    ActivityLegendRow(
                        color: .standRing,
                        label: String(localized: "Steps"),
                        value: summary.steps.formattedSteps,
                        progress: stepsProgress
                    )
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct ActivityLegendRow: View {
    let color: Color
    let label: String
    let value: String
    let progress: Double

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.subheadline.bold())
            }

            Spacer()

            Text("\(Int(min(progress, 1) * 100))%")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Nutrition Quick Card
struct NutritionQuickCard: View {
    let targets: NutritionTargets

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(String(localized: "Nutrition Targets"))
                    .font(.headline)

                Spacer()

                NavigationLink(destination: NutritionView()) {
                    Text(String(localized: "Details"))
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }

            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("\(Int(targets.targetCalories))")
                        .font(.title2.bold())

                    Text(String(localized: "Target kcal"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 40)

                VStack(spacing: 4) {
                    Text("\(Int(targets.proteinGrams))g")
                        .font(.title2.bold())
                        .foregroundStyle(Color.proteinColor)

                    Text(String(localized: "Protein"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 40)

                VStack(spacing: 4) {
                    Text("\(Int(targets.carbGrams))g")
                        .font(.title2.bold())
                        .foregroundStyle(Color.carbsColor)

                    Text(String(localized: "Carbs"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 40)

                VStack(spacing: 4) {
                    Text("\(Int(targets.fatGrams))g")
                        .font(.title2.bold())
                        .foregroundStyle(Color.fatColor)

                    Text(String(localized: "Fat"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Recent Workouts Card
struct RecentWorkoutsCard: View {
    let workouts: [Workout]

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(String(localized: "Recent Workouts"))
                    .font(.headline)

                Spacer()

                NavigationLink(destination: WorkoutsView()) {
                    Text(String(localized: "See All"))
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }

            ForEach(workouts.prefix(3)) { workout in
                CompactWorkoutRow(workout: workout)
                if workout.id != workouts.prefix(3).last?.id {
                    Divider()
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Insights Card
struct InsightsCard: View {
    let insights: [Insight]

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(String(localized: "Insights"))
                    .font(.headline)

                Spacer()
            }

            ForEach(insights.prefix(3)) { insight in
                InsightRow(insight: insight)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct InsightRow: View {
    let insight: Insight

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: insight.type.icon)
                .font(.title3)
                .foregroundStyle(priorityColor)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(insight.title)
                    .font(.subheadline.bold())

                Text(insight.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            if insight.actionable {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }

    private var priorityColor: Color {
        switch insight.priority {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .blue
        case .low: return .gray
        }
    }
}

// MARK: - Weight Input Sheet
struct WeightInputSheet: View {
    let currentWeight: Double
    let onSave: (Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var weight: Double

    init(currentWeight: Double, onSave: @escaping (Double) -> Void) {
        self.currentWeight = currentWeight
        self.onSave = onSave
        _weight = State(initialValue: currentWeight)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text(String(localized: "Log Weight"))
                    .font(.title2.bold())

                Text("\(weight, specifier: "%.1f") kg")
                    .font(.system(size: 48, weight: .bold, design: .rounded))

                Slider(value: $weight, in: 30...200, step: 0.1)
                    .padding(.horizontal)

                HStack {
                    Button("-0.5") {
                        weight = max(30, weight - 0.5)
                    }
                    .buttonStyle(.bordered)

                    Button("-0.1") {
                        weight = max(30, weight - 0.1)
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    Button("+0.1") {
                        weight = min(200, weight + 0.1)
                    }
                    .buttonStyle(.bordered)

                    Button("+0.5") {
                        weight = min(200, weight + 0.5)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)

                Spacer()

                Button(action: {
                    onSave(weight)
                    dismiss()
                }) {
                    Text(String(localized: "Save"))
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "Cancel")) {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    DashboardView()
        .environmentObject(UserProfile())
}
