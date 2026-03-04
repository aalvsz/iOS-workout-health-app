import SwiftUI

struct WorkoutDetailView: View {
    let workout: Workout
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(activityColor.opacity(0.15))
                                .frame(width: 80, height: 80)

                            Image(systemName: workout.activityIcon)
                                .font(.largeTitle)
                                .foregroundStyle(activityColor)
                        }

                        Text(workout.activityType)
                            .font(.title.bold())

                        Text(workout.date.longDate)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top)

                    // Main Stats
                    HStack(spacing: 0) {
                        StatBlock(
                            value: workout.formattedDuration,
                            label: String(localized: "Duration"),
                            icon: "clock.fill"
                        )

                        Divider()
                            .frame(height: 50)

                        StatBlock(
                            value: "\(Int(workout.activeCalories))",
                            label: String(localized: "Calories"),
                            icon: "flame.fill"
                        )

                        if let distance = workout.distance {
                            Divider()
                                .frame(height: 50)

                            StatBlock(
                                value: (distance / 1000).formatted1,
                                label: String(localized: "km"),
                                icon: "map.fill"
                            )
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Time Details
                    VStack(spacing: 16) {
                        HStack {
                            Text(String(localized: "Time Details"))
                                .font(.headline)
                            Spacer()
                        }

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(String(localized: "Start"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Text(workout.startTime.timeOnly)
                                    .font(.title3.bold())
                            }

                            Spacer()

                            Image(systemName: "arrow.right")
                                .foregroundStyle(.secondary)

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text(String(localized: "End"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Text(workout.endTime.timeOnly)
                                    .font(.title3.bold())
                            }
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Heart Rate (if available)
                    if let avgHR = workout.averageHeartRate {
                        VStack(spacing: 16) {
                            HStack {
                                Text(String(localized: "Heart Rate"))
                                    .font(.headline)
                                Spacer()
                            }

                            HStack {
                                Image(systemName: "heart.fill")
                                    .font(.title)
                                    .foregroundStyle(.red)

                                VStack(alignment: .leading) {
                                    Text(String(localized: "\(Int(avgHR)) bpm"))
                                        .font(.title2.bold())

                                    Text(String(localized: "Average"))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    // Calories Breakdown
                    VStack(spacing: 16) {
                        HStack {
                            Text(String(localized: "Energy"))
                                .font(.headline)
                            Spacer()
                        }

                        HStack(spacing: 20) {
                            VStack(spacing: 4) {
                                Text("\(Int(workout.activeCalories))")
                                    .font(.title.bold())
                                    .foregroundStyle(.orange)

                                Text(String(localized: "Active kcal"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            // Equivalent activities
                            VStack(alignment: .leading, spacing: 8) {
                                EquivalentRow(
                                    icon: "cup.and.saucer.fill",
                                    text: String(localized: "\(Int(workout.activeCalories / 5)) coffees")
                                )

                                EquivalentRow(
                                    icon: "🍌",
                                    text: String(localized: "\(Int(workout.activeCalories / 90)) bananas")
                                )

                                EquivalentRow(
                                    icon: "figure.walk",
                                    text: String(localized: "\(Int(workout.activeCalories / 40)) min walking")
                                )
                            }
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    Spacer(minLength: 40)
                }
                .padding()
            }
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

    private var activityColor: Color {
        switch workout.activityType.lowercased() {
        case let type where type.contains("run"):
            return .red
        case let type where type.contains("cycling"):
            return .green
        case let type where type.contains("swim"):
            return .cyan
        case let type where type.contains("strength"):
            return .purple
        case let type where type.contains("yoga"):
            return .teal
        case let type where type.contains("hiit"):
            return .orange
        default:
            return .blue
        }
    }
}

struct StatBlock: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title2.bold())

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct EquivalentRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            if icon.count == 1 {
                Text(icon)
            } else {
                Image(systemName: icon)
                    .foregroundStyle(.secondary)
            }

            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    WorkoutDetailView(
        workout: Workout(
            date: Date(),
            activityType: "Running",
            activityIcon: "figure.run",
            durationMinutes: 45,
            activeCalories: 420,
            distance: 6500,
            averageHeartRate: 155,
            startTime: Date().addingTimeInterval(-3600),
            endTime: Date()
        )
    )
}
