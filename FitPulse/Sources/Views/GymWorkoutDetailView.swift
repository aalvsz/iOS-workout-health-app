import SwiftUI

struct GymWorkoutDetailView: View {
    let workout: GymWorkout
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 80, height: 80)

                            Image(systemName: "dumbbell.fill")
                                .font(.largeTitle)
                                .foregroundStyle(.blue)
                        }

                        Text(workout.name)
                            .font(.title.bold())

                        Text(workout.date.longDate)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top)

                    // Stats
                    HStack(spacing: 0) {
                        WorkoutStatBlock(
                            value: workout.formattedDuration,
                            label: "Duration",
                            icon: "clock.fill",
                            color: .green
                        )

                        Divider().frame(height: 50)

                        WorkoutStatBlock(
                            value: "\(Int(workout.calories))",
                            label: "Calories",
                            icon: "flame.fill",
                            color: .orange
                        )

                        if let hr = workout.averageHeartRate {
                            Divider().frame(height: 50)

                            WorkoutStatBlock(
                                value: "\(Int(hr))",
                                label: "Avg HR",
                                icon: "heart.fill",
                                color: .red
                            )
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Exercises
                    if !workout.exercises.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Exercises")
                                .font(.headline)

                            ForEach(workout.exercises) { exercise in
                                ExerciseCard(exercise: exercise)
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    // Volume Summary
                    if !workout.exercises.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Volume Summary")
                                .font(.headline)

                            HStack {
                                VolumeStatBox(
                                    value: "\(workout.exercises.count)",
                                    label: "Exercises"
                                )

                                VolumeStatBox(
                                    value: "\(totalSets)",
                                    label: "Total Sets"
                                )

                                VolumeStatBox(
                                    value: "\(Int(totalVolume))",
                                    label: "Volume (kg)"
                                )
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    // Notes
                    if let notes = workout.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.headline)

                            Text(notes)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var totalSets: Int {
        workout.exercises.reduce(0) { $0 + $1.sets.count }
    }

    private var totalVolume: Double {
        workout.exercises.reduce(0) { $0 + $1.totalVolume }
    }
}

struct WorkoutStatBlock: View {
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

struct ExerciseCard: View {
    let exercise: Exercise

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(exercise.name)
                    .font(.headline)

                Spacer()

                Text("\(exercise.sets.count) sets")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.15))
                    .clipShape(Capsule())
            }

            // Sets table
            VStack(spacing: 4) {
                HStack {
                    Text("Set")
                        .frame(width: 40, alignment: .leading)
                    Text("Weight")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Reps")
                        .frame(width: 50, alignment: .trailing)
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                Divider()

                ForEach(exercise.sets) { set in
                    HStack {
                        Text("\(set.setNumber)")
                            .frame(width: 40, alignment: .leading)

                        if set.isWarmup {
                            HStack(spacing: 4) {
                                Text("\(Int(set.weight)) kg")
                                Text("(warmup)")
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Text("\(Int(set.weight)) kg")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Text("\(set.reps)")
                            .frame(width: 50, alignment: .trailing)
                    }
                    .font(.subheadline)
                    .foregroundStyle(set.isWarmup ? .secondary : .primary)
                }
            }

            // Best set
            if let bestSet = exercise.sets.filter({ !$0.isWarmup }).max(by: { $0.weight < $1.weight }) {
                HStack {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                    Text("Best: \(Int(bestSet.weight)) kg x \(bestSet.reps)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct VolumeStatBox: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    GymWorkoutDetailView(
        workout: GymWorkout(
            id: UUID(),
            date: Date(),
            name: "Push Day",
            duration: 75,
            calories: 450,
            exercises: [
                Exercise(name: "Bench Press", sets: [
                    ExerciseSet(setNumber: 1, weight: 40, reps: 10, isWarmup: true),
                    ExerciseSet(setNumber: 2, weight: 60, reps: 8),
                    ExerciseSet(setNumber: 3, weight: 70, reps: 6),
                    ExerciseSet(setNumber: 4, weight: 70, reps: 5)
                ]),
                Exercise(name: "Overhead Press", sets: [
                    ExerciseSet(setNumber: 1, weight: 30, reps: 10),
                    ExerciseSet(setNumber: 2, weight: 40, reps: 8),
                    ExerciseSet(setNumber: 3, weight: 40, reps: 7)
                ])
            ],
            averageHeartRate: 135,
            notes: "Felt strong today. Increased bench weight."
        )
    )
}
