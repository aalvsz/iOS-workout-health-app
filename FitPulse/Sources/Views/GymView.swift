import SwiftUI

struct GymView: View {
    @StateObject private var viewModel = GymViewModel()
    @State private var showingWorkoutPlanGenerator = false
    @State private var selectedWorkout: GymWorkout?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Quick Stats
                    WeeklyGymStats(workouts: viewModel.thisWeekWorkouts)

                    // Next Workout Suggestion
                    if let suggestion = viewModel.nextWorkoutSuggestion {
                        NextWorkoutCard(
                            suggestion: suggestion,
                            onStart: { viewModel.startWorkout(suggestion) }
                        )
                    } else {
                        GenerateWorkoutCard(onTap: { showingWorkoutPlanGenerator = true })
                    }

                    // Current Plan (if exists)
                    if let plan = viewModel.currentPlan {
                        CurrentPlanCard(plan: plan)
                    }

                    // Recent Workouts
                    RecentGymWorkoutsSection(
                        workouts: viewModel.recentWorkouts,
                        onSelect: { selectedWorkout = $0 }
                    )

                    // Training Insights
                    if !viewModel.insights.isEmpty {
                        TrainingInsightsCard(insights: viewModel.insights)
                    }
                }
                .padding()
            }
            .navigationTitle("Training")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingWorkoutPlanGenerator = true }) {
                        Image(systemName: "wand.and.stars")
                    }
                }
            }
            .refreshable {
                await viewModel.loadData()
            }
            .task {
                await viewModel.loadData()
            }
            .sheet(isPresented: $showingWorkoutPlanGenerator) {
                WorkoutPlanGeneratorView(viewModel: viewModel)
            }
            .sheet(item: $selectedWorkout) { workout in
                GymWorkoutDetailView(workout: workout)
            }
        }
    }
}

// MARK: - Weekly Gym Stats
struct WeeklyGymStats: View {
    let workouts: [GymWorkout]

    private var totalDuration: Double {
        workouts.reduce(0) { $0 + $1.duration }
    }

    private var totalCalories: Double {
        workouts.reduce(0) { $0 + $1.calories }
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("This Week")
                    .font(.headline)
                Spacer()
                Text("\(workouts.count) sessions")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 0) {
                StatBox(value: "\(workouts.count)", label: "Workouts", icon: "dumbbell.fill", color: .blue)
                Divider().frame(height: 40)
                StatBox(value: "\(Int(totalDuration))", label: "Minutes", icon: "clock.fill", color: .green)
                Divider().frame(height: 40)
                StatBox(value: "\(Int(totalCalories))", label: "Calories", icon: "flame.fill", color: .orange)
            }

            // Week calendar
            WeekCalendarView(workouts: workouts)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct StatBox: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            Text(value)
                .font(.title2.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct WeekCalendarView: View {
    let workouts: [GymWorkout]

    private var weekDays: [(String, Date, Bool)] {
        let calendar = Calendar.current
        let startOfWeek = Date().startOfWeek

        return (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: startOfWeek)!
            let hasWorkout = workouts.contains { calendar.isDate($0.date, inSameDayAs: date) }
            return (date.shortDayOfWeek, date, hasWorkout)
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(weekDays, id: \.1) { day in
                VStack(spacing: 6) {
                    Text(day.0)
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    ZStack {
                        Circle()
                            .fill(day.2 ? Color.blue : Color.clear)
                            .frame(width: 32, height: 32)

                        if day.2 {
                            Image(systemName: "checkmark")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                        } else {
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                .frame(width: 32, height: 32)
                        }
                    }

                    if Calendar.current.isDateInToday(day.1) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 4, height: 4)
                    } else {
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 4, height: 4)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Next Workout Card
struct NextWorkoutCard: View {
    let suggestion: WorkoutSuggestion
    let onStart: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Suggested Workout")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(suggestion.name)
                        .font(.title2.bold())
                }

                Spacer()

                Image(systemName: "sparkles")
                    .font(.title)
                    .foregroundStyle(.yellow)
            }

            Text(suggestion.focus)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Preview exercises
            VStack(alignment: .leading, spacing: 8) {
                ForEach(suggestion.exercises.prefix(4)) { exercise in
                    HStack {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 6, height: 6)
                        Text(exercise.name)
                            .font(.subheadline)
                        Spacer()
                        Text("\(exercise.sets) x \(exercise.reps)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if suggestion.exercises.count > 4 {
                    Text("+ \(suggestion.exercises.count - 4) more exercises")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Button(action: onStart) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Start Workout")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Generate Workout Card
struct GenerateWorkoutCard: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 40))
                    .foregroundStyle(.blue)

                Text("Generate Workout Plan")
                    .font(.headline)

                Text("Get a personalized training plan based on your goals and history")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Current Plan Card
struct CurrentPlanCard: View {
    let plan: WorkoutPlan

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Current Plan")
                    .font(.headline)
                Spacer()
                Text(plan.name)
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.15))
                    .clipShape(Capsule())
            }

            Text(plan.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(plan.days) { day in
                        PlanDayCard(day: day)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct PlanDayCard: View {
    let day: WorkoutDay

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(day.name)
                .font(.subheadline.bold())

            Text(day.focus)
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            ForEach(day.exercises.prefix(3)) { exercise in
                Text(exercise.name)
                    .font(.caption)
                    .lineLimit(1)
            }

            if day.exercises.count > 3 {
                Text("+\(day.exercises.count - 3) more")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .frame(width: 140)
        .background(Color.secondary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Recent Workouts Section
struct RecentGymWorkoutsSection: View {
    let workouts: [GymWorkout]
    let onSelect: (GymWorkout) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Workouts")
                    .font(.headline)
                Spacer()
                Text("\(workouts.count) total")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(workouts.prefix(5)) { workout in
                GymWorkoutRow(workout: workout, onTap: { onSelect(workout) })
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct GymWorkoutRow: View {
    let workout: GymWorkout
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: "dumbbell.fill")
                        .foregroundStyle(.blue)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(workout.name)
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)

                    HStack(spacing: 8) {
                        Text(workout.formattedDuration)
                        Text("•")
                        Text("\(Int(workout.calories)) kcal")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(workout.date.relativeDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if !workout.exercises.isEmpty {
                        Text("\(workout.exercises.count) exercises")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Training Insights Card
struct TrainingInsightsCard: View {
    let insights: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                Text("Insights")
                    .font(.headline)
            }

            ForEach(insights, id: \.self) { insight in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.blue)
                    Text(insight)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    GymView()
        .environmentObject(UserProfile())
}
