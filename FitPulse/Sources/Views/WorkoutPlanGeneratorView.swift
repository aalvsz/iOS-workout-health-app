import SwiftUI

struct WorkoutPlanGeneratorView: View {
    @ObservedObject var viewModel: GymViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var goalType: WorkoutGoal.GoalType = .buildMuscle
    @State private var experienceLevel: WorkoutGoal.ExperienceLevel = .intermediate
    @State private var daysPerWeek = 4
    @State private var sessionLength = 60
    @State private var isGenerating = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 50))
                            .foregroundStyle(.blue)

                        Text("Generate Your Plan")
                            .font(.title2.bold())

                        Text("Tell us about your goals and we'll create a personalized workout plan")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                    .listRowBackground(Color.clear)
                }

                Section("What's your goal?") {
                    Picker("Goal", selection: $goalType) {
                        ForEach(WorkoutGoal.GoalType.allCases, id: \.self) { goal in
                            Text(goal.rawValue).tag(goal)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Experience Level") {
                    Picker("Experience", selection: $experienceLevel) {
                        ForEach(WorkoutGoal.ExperienceLevel.allCases, id: \.self) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Schedule") {
                    Stepper("Days per week: \(daysPerWeek)", value: $daysPerWeek, in: 2...6)

                    VStack(alignment: .leading) {
                        HStack {
                            Text("Session length")
                            Spacer()
                            Text("\(sessionLength) min")
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: Binding(
                            get: { Double(sessionLength) },
                            set: { sessionLength = Int($0) }
                        ), in: 30...120, step: 15)
                    }
                }

                Section {
                    Button(action: generatePlan) {
                        HStack {
                            if isGenerating {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "sparkles")
                            }
                            Text(isGenerating ? "Generating..." : "Generate Plan")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isGenerating ? Color.gray : Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isGenerating)
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("New Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func generatePlan() {
        isGenerating = true

        let goal = WorkoutGoal(
            type: goalType,
            daysPerWeek: daysPerWeek,
            sessionLength: sessionLength,
            experienceLevel: experienceLevel
        )

        Task {
            await viewModel.generateWorkoutPlan(goal: goal)
            isGenerating = false
            dismiss()
        }
    }
}

#Preview {
    WorkoutPlanGeneratorView(viewModel: GymViewModel())
}
