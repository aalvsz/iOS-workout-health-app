import SwiftUI

struct WorkoutCard: View {
    let workout: Workout
    let onTap: (() -> Void)?

    init(workout: Workout, onTap: (() -> Void)? = nil) {
        self.workout = workout
        self.onTap = onTap
    }

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 16) {
                // Activity Icon
                ZStack {
                    Circle()
                        .fill(activityColor.opacity(0.15))
                        .frame(width: 50, height: 50)

                    Image(systemName: workout.activityIcon)
                        .font(.title2)
                        .foregroundStyle(activityColor)
                }

                // Workout Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.activityType)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    HStack(spacing: 12) {
                        Label(workout.formattedDuration, systemImage: "clock")
                        Label("\(Int(workout.activeCalories)) kcal", systemImage: "flame")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                // Time
                VStack(alignment: .trailing, spacing: 4) {
                    Text(workout.date.relativeDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(workout.startTime.timeOnly)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private var activityColor: Color {
        switch workout.activityType.lowercased() {
        case let type where type.contains("run"):
            return .red
        case let type where type.contains("cycling") || type.contains("cycle"):
            return .green
        case let type where type.contains("swim"):
            return .cyan
        case let type where type.contains("strength") || type.contains("weight"):
            return .purple
        case let type where type.contains("yoga") || type.contains("stretch"):
            return .teal
        case let type where type.contains("hiit"):
            return .orange
        case let type where type.contains("walk"):
            return .mint
        default:
            return .blue
        }
    }
}

// MARK: - Compact Workout Row
struct CompactWorkoutRow: View {
    let workout: Workout

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: workout.activityIcon)
                .font(.body)
                .foregroundStyle(.blue)
                .frame(width: 24)

            Text(workout.activityType)
                .font(.subheadline)

            Spacer()

            Text(workout.formattedDuration)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("\(Int(workout.activeCalories)) kcal")
                .font(.caption.bold())
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Workout Stats Card
struct WorkoutStatsCard: View {
    let totalWorkouts: Int
    let totalMinutes: Double
    let totalCalories: Double
    let period: String

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Workout Summary")
                    .font(.headline)

                Spacer()

                Text(period)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 0) {
                WorkoutStatItem(
                    value: "\(totalWorkouts)",
                    label: "Workouts",
                    icon: "figure.run"
                )

                Divider()
                    .frame(height: 40)

                WorkoutStatItem(
                    value: totalMinutes.formattedMinutes,
                    label: "Duration",
                    icon: "clock"
                )

                Divider()
                    .frame(height: 40)

                WorkoutStatItem(
                    value: totalCalories.compact,
                    label: "Calories",
                    icon: "flame"
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct WorkoutStatItem: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.headline)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Workout Type Breakdown
struct WorkoutTypeBreakdown: View {
    let workouts: [Workout]

    private var breakdown: [(String, Int, Color)] {
        var counts: [String: Int] = [:]
        for workout in workouts {
            counts[workout.activityType, default: 0] += 1
        }

        return counts.sorted { $0.value > $1.value }
            .prefix(5)
            .enumerated()
            .map { (index, item) in
                let colors: [Color] = [.red, .blue, .green, .orange, .purple]
                return (item.key, item.value, colors[index % colors.count])
            }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Workout Types")
                .font(.headline)

            ForEach(breakdown.indices, id: \.self) { index in
                let item = breakdown[index]
                HStack(spacing: 12) {
                    Circle()
                        .fill(item.2)
                        .frame(width: 8, height: 8)

                    Text(item.0)
                        .font(.subheadline)

                    Spacer()

                    Text("\(item.1)")
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Weekly Workout Goal
struct WeeklyWorkoutGoal: View {
    let completed: Int
    let goal: Int

    private var progress: Double {
        guard goal > 0 else { return 0 }
        return Double(completed) / Double(goal)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Weekly Goal")
                    .font(.headline)

                Spacer()

                Text("\(completed)/\(goal)")
                    .font(.title3.bold())
                    .foregroundStyle(progress >= 1 ? .green : .primary)
            }

            // Progress dots
            HStack(spacing: 8) {
                ForEach(0..<goal, id: \.self) { index in
                    Circle()
                        .fill(index < completed ? Color.green : Color.gray.opacity(0.3))
                        .frame(width: 24, height: 24)
                        .overlay {
                            if index < completed {
                                Image(systemName: "checkmark")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.white)
                            }
                        }
                }

                Spacer()
            }

            if progress >= 1 {
                Label("Goal achieved!", systemImage: "star.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
            } else {
                Text("\(goal - completed) more to reach your goal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            WorkoutCard(
                workout: Workout(
                    date: Date(),
                    activityType: "Running",
                    activityIcon: "figure.run",
                    durationMinutes: 45,
                    activeCalories: 350,
                    distance: 5200,
                    startTime: Date().addingTimeInterval(-3600),
                    endTime: Date()
                )
            )

            WorkoutStatsCard(
                totalWorkouts: 5,
                totalMinutes: 280,
                totalCalories: 1450,
                period: "This Week"
            )

            WeeklyWorkoutGoal(completed: 3, goal: 5)
        }
        .padding()
    }
}
