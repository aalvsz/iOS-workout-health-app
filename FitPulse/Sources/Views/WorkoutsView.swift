import SwiftUI

struct WorkoutsView: View {
    @StateObject private var viewModel = WorkoutsViewModel()
    @State private var showingWorkoutDetail = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Weekly Goal Progress
                    WeeklyWorkoutGoal(
                        completed: viewModel.weeklyStats?.totalWorkouts ?? 0,
                        goal: viewModel.profile.weeklyWorkoutGoal
                    )

                    // Time Range Picker
                    Picker("Time Range", selection: $viewModel.selectedTimeRange) {
                        ForEach(WorkoutsViewModel.TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Weekly Stats
                    if let stats = viewModel.weeklyStats {
                        WorkoutStatsCard(
                            totalWorkouts: stats.totalWorkouts,
                            totalMinutes: stats.totalDurationMinutes,
                            totalCalories: stats.totalCaloriesBurned,
                            period: "This Week"
                        )
                    }

                    // Workout Type Breakdown
                    if !viewModel.filteredWorkouts.isEmpty {
                        WorkoutTypeBreakdown(workouts: viewModel.filteredWorkouts)
                    }

                    // Workouts List
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Workout History")
                            .font(.headline)
                            .padding(.horizontal)

                        if viewModel.filteredWorkouts.isEmpty && !viewModel.isLoading {
                            EmptyWorkoutsView()
                        } else {
                            ForEach(viewModel.sortedDates, id: \.self) { date in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(date.relativeDescription)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal)

                                    ForEach(viewModel.workoutsByDate[date] ?? []) { workout in
                                        WorkoutCard(workout: workout) {
                                            viewModel.selectedWorkout = workout
                                            showingWorkoutDetail = true
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Workouts")
            .refreshable {
                await viewModel.refreshWorkouts()
            }
            .task {
                await viewModel.loadWorkouts()
            }
            .sheet(isPresented: $showingWorkoutDetail) {
                if let workout = viewModel.selectedWorkout {
                    WorkoutDetailView(workout: workout)
                }
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

// MARK: - Empty State
struct EmptyWorkoutsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.run")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Workouts Yet")
                .font(.headline)

            Text("Your workouts from Apple Health will appear here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Weekly Calendar
struct WeeklyWorkoutCalendar: View {
    let workouts: [Workout]
    let goal: Int

    private var weekDays: [(String, Date, Int)] {
        Date.datesForCurrentWeek().map { date in
            let count = workouts.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }.count
            return (date.shortDayOfWeek, date, count)
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                ForEach(weekDays, id: \.1) { day in
                    VStack(spacing: 8) {
                        Text(day.0)
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        ZStack {
                            Circle()
                                .fill(day.2 > 0 ? Color.green : Color.gray.opacity(0.2))
                                .frame(width: 32, height: 32)

                            if day.2 > 0 {
                                Text("\(day.2)")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                            }
                        }

                        if Calendar.current.isDateInToday(day.1) {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 6, height: 6)
                        } else {
                            Circle()
                                .fill(Color.clear)
                                .frame(width: 6, height: 6)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    WorkoutsView()
        .environmentObject(UserProfile())
}
