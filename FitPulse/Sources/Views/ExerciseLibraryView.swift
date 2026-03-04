import SwiftUI

struct ExerciseLibraryView: View {
    @State private var searchText = ""
    @State private var selectedMuscleGroup: MuscleGroup?
    @State private var selectedExercise: ExerciseLibraryItem?

    private var filteredExercises: [ExerciseLibraryItem] {
        var result = ExerciseLibrary.allExercises
        if let group = selectedMuscleGroup {
            result = ExerciseLibrary.exercises(for: group)
        }
        if !searchText.isEmpty {
            let lower = searchText.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(lower) ||
                $0.primaryMuscles.contains(where: { $0.rawValue.lowercased().contains(lower) }) ||
                $0.equipment.rawValue.lowercased().contains(lower)
            }
        }
        return result.sorted { $0.name < $1.name }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Muscle group filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(label: String(localized: "All"), isSelected: selectedMuscleGroup == nil) {
                        selectedMuscleGroup = nil
                    }
                    ForEach(MuscleGroup.allCases, id: \.self) { group in
                        FilterChip(label: group.displayName, isSelected: selectedMuscleGroup == group) {
                            selectedMuscleGroup = selectedMuscleGroup == group ? nil : group
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }

            List(filteredExercises) { exercise in
                Button(action: { selectedExercise = exercise }) {
                    ExerciseLibraryRow(exercise: exercise)
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
            .searchable(text: $searchText, prompt: String(localized: "Search exercises"))
        }
        .navigationTitle(String(localized: "Exercise Library"))
        .sheet(item: $selectedExercise) { exercise in
            ExerciseDetailView(exercise: exercise)
        }
    }
}

// MARK: - Exercise Row
struct ExerciseLibraryRow: View {
    let exercise: ExerciseLibraryItem

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: exercise.primaryMuscles.first?.icon ?? "figure.strengthtraining.traditional")
                    .foregroundStyle(.blue)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.subheadline.bold())
                HStack(spacing: 6) {
                    Text(exercise.primaryMuscles.map(\.displayName).joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\u{00B7}")
                        .foregroundStyle(.tertiary)
                    Text(exercise.equipment.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            DifficultyBadge(difficulty: exercise.difficulty)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Exercise Detail View
struct ExerciseDetailView: View {
    let exercise: ExerciseLibraryItem
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(exercise.description)
                            .font(.body)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 12) {
                            Label(exercise.equipment.displayName, systemImage: exercise.equipment.icon)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.secondary.opacity(0.1))
                                .clipShape(Capsule())

                            DifficultyBadge(difficulty: exercise.difficulty)
                        }
                    }

                    // Muscles
                    VStack(alignment: .leading, spacing: 12) {
                        Text(String(localized: "Muscles Worked"))
                            .font(.headline)

                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                Text(String(localized: "Primary"))
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                                    .frame(width: 70, alignment: .leading)
                                ForEach(exercise.primaryMuscles, id: \.self) { muscle in
                                    Text(muscle.displayName)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.15))
                                        .clipShape(Capsule())
                                }
                            }

                            if !exercise.secondaryMuscles.isEmpty {
                                HStack(spacing: 8) {
                                    Text(String(localized: "Secondary"))
                                        .font(.caption.bold())
                                        .foregroundStyle(.secondary)
                                        .frame(width: 70, alignment: .leading)
                                    ForEach(exercise.secondaryMuscles, id: \.self) { muscle in
                                        Text(muscle.displayName)
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.orange.opacity(0.15))
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Instructions
                    if !exercise.instructions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(String(localized: "How To Perform"))
                                .font(.headline)

                            ForEach(Array(exercise.instructions.enumerated()), id: \.offset) { index, step in
                                HStack(alignment: .top, spacing: 12) {
                                    Text("\(index + 1)")
                                        .font(.caption.bold())
                                        .foregroundStyle(.white)
                                        .frame(width: 24, height: 24)
                                        .background(Color.blue)
                                        .clipShape(Circle())

                                    Text(step)
                                        .font(.subheadline)
                                }
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    // Common Mistakes
                    if !exercise.commonMistakes.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(String(localized: "Common Mistakes"))
                                .font(.headline)

                            ForEach(exercise.commonMistakes, id: \.self) { mistake in
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                    Text(mistake)
                                        .font(.subheadline)
                                }
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding()
            }
            .navigationTitle(exercise.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "Done")) { dismiss() }
                }
            }
        }
    }
}

// MARK: - Reusable Components
struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color.secondary.opacity(0.15))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct DifficultyBadge: View {
    let difficulty: ExerciseDifficulty

    private var color: Color {
        switch difficulty {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        }
    }

    var body: some View {
        Text(difficulty.displayName)
            .font(.caption2.bold())
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}
