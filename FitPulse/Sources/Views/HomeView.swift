import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var engagementViewModel = EngagementViewModel()
    @State private var showingWaterLog = false
    @State private var showingMealLog = false
    @State private var showingWeightLog = false
    @State private var showingWorkout = false
    @State private var showingEngagement = false

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 24) {
                        // Greeting
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(viewModel.greeting)
                                    .font(.title2.bold())

                                Text(Date().formatted(.dateTime.weekday(.wide).month().day()))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            // Profile avatar
                            NavigationLink(destination: ProfileView()) {
                                ZStack {
                                    Circle()
                                        .fill(.blue.opacity(0.1))
                                        .frame(width: 44, height: 44)

                                    Text(viewModel.profileInitial)
                                        .font(.headline)
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .padding(.horizontal)

                        // Today's Priority - THE KEY DIFFERENTIATOR
                        TodaysPriorityCard(
                            priority: viewModel.todaysPriority,
                            onAction: {
                                handlePriorityAction(viewModel.todaysPriority.action)
                            }
                        )
                        .padding(.horizontal)

                        // Momentum Ring
                        MomentumRing(momentum: viewModel.momentum)

                        // Streak Summary Row
                        if !engagementViewModel.streaks.isEmpty {
                            StreakSummaryRow(streaks: engagementViewModel.streaks)
                                .padding(.horizontal)
                        }

                        // Active Challenge Card
                        if let challenge = engagementViewModel.activeChallenge {
                            CompactChallengeCard(challenge: challenge) {
                                showingEngagement = true
                            }
                            .padding(.horizontal)
                        }

                        // Goal Progress Card
                        if let prediction = engagementViewModel.goalPrediction {
                            CompactGoalProgress(prediction: prediction) {
                                showingEngagement = true
                            }
                            .padding(.horizontal)
                        }

                        // Quick Stats Row
                        HStack(spacing: 12) {
                            QuickStatCard(
                                icon: "flame.fill",
                                value: "\(viewModel.caloriesBurned)",
                                label: "Burned",
                                color: .orange
                            )

                            QuickStatCard(
                                icon: "fork.knife",
                                value: "\(viewModel.caloriesConsumed)",
                                label: "Eaten",
                                color: .green
                            )

                            QuickStatCard(
                                icon: "drop.fill",
                                value: viewModel.hydrationText,
                                label: "Water",
                                color: .cyan
                            )
                        }
                        .padding(.horizontal)

                        // Today's Activity Summary
                        if !viewModel.todayWorkouts.isEmpty {
                            TodayActivityCard(workouts: viewModel.todayWorkouts)
                                .padding(.horizontal)
                        }

                        // Recent Insight (just one, not overwhelming)
                        if let insight = viewModel.topInsight {
                            InsightCard(insight: insight)
                                .padding(.horizontal)
                        }

                        Spacer(minLength: 100) // Space for quick actions bar
                    }
                    .padding(.top)
                }
                .refreshable {
                    await viewModel.refreshData()
                }

                // Floating Quick Actions
                VStack {
                    Spacer()

                    QuickActionsBar(
                        onLogWater: { showingWaterLog = true },
                        onLogMeal: { showingMealLog = true },
                        onStartWorkout: { showingWorkout = true },
                        onLogWeight: { showingWeightLog = true }
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
            }
            .navigationBarHidden(true)
            .task {
                await viewModel.loadData()
                await engagementViewModel.loadData()
            }
            .sheet(isPresented: $showingWaterLog) {
                QuickWaterLogSheet(onLog: { amount in
                    viewModel.logWater(amount: amount)
                })
                .presentationDetents([.height(300)])
            }
            .sheet(isPresented: $showingMealLog) {
                NavigationStack {
                    NutritionView()
                }
            }
            .sheet(isPresented: $showingWeightLog) {
                WeightInputSheet(
                    currentWeight: viewModel.currentWeight,
                    onSave: { weight in
                        Task {
                            await viewModel.logWeight(weight)
                        }
                    }
                )
            }
            .sheet(isPresented: $showingWorkout) {
                NavigationStack {
                    GymView()
                }
            }
            .sheet(isPresented: $showingEngagement) {
                EngagementView()
            }
        }
    }

    private func handlePriorityAction(_ action: TodaysPriority.PriorityAction?) {
        guard let action = action else { return }

        switch action {
        case .startWorkout:
            showingWorkout = true
        case .logMeal:
            showingMealLog = true
        case .logWater:
            showingWaterLog = true
        case .rest, .viewDetails:
            break
        }
    }
}

// MARK: - Quick Stat Card
struct QuickStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(value)
                .font(.headline)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Today Activity Card
struct TodayActivityCard: View {
    let workouts: [Workout]

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Today's Activity")
                    .font(.headline)
                Spacer()
            }

            ForEach(workouts.prefix(2)) { workout in
                HStack(spacing: 12) {
                    Image(systemName: workout.activityIcon)
                        .font(.title3)
                        .foregroundStyle(.orange)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(workout.activityType)
                            .font(.subheadline.bold())

                        Text("\(workout.formattedDuration) • \(Int(workout.activeCalories)) kcal")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Single Insight Card
struct InsightCard: View {
    let insight: Insight

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: insight.type.icon)
                .font(.title2)
                .foregroundStyle(priorityColor)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.subheadline.bold())

                Text(insight.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
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

// MARK: - Quick Water Log Sheet
struct QuickWaterLogSheet: View {
    let onLog: (Int) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Text("Log Water")
                .font(.title2.bold())

            HStack(spacing: 16) {
                WaterButton(amount: 250, label: "Glass", icon: "drop.fill") {
                    onLog(250)
                    dismiss()
                }

                WaterButton(amount: 500, label: "Bottle", icon: "waterbottle.fill") {
                    onLog(500)
                    dismiss()
                }

                WaterButton(amount: 750, label: "Large", icon: "drop.circle.fill") {
                    onLog(750)
                    dismiss()
                }
            }

            Button("Cancel") {
                dismiss()
            }
            .foregroundStyle(.secondary)
        }
        .padding()
    }
}

struct WaterButton: View {
    let amount: Int
    let label: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundStyle(.cyan)

                Text("\(amount)ml")
                    .font(.headline)

                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color.cyan.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeView()
}
