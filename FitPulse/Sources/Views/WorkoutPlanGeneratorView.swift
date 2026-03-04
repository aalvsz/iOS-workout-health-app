import SwiftUI

struct WorkoutPlanGeneratorView: View {
    @ObservedObject var viewModel: GymViewModel
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss

    @State private var showingPaywall = false

    // MARK: - Step Navigation
    @State private var currentStep = 1
    private let totalSteps = 3

    // MARK: - Step 1: Goal & Experience
    @State private var goalType: WorkoutGoal.GoalType = .buildMuscle
    @State private var experienceLevel: WorkoutGoal.ExperienceLevel = .intermediate

    // MARK: - Step 2: Muscle Groups & Equipment
    @State private var selectedMuscleGroups: Set<MuscleGroup> = []
    @State private var selectedEquipment: Set<ExerciseEquipment> = []

    // MARK: - Step 3: Schedule & Preferences
    @State private var daysPerWeek = 4
    @State private var sessionLength = 60
    @State private var splitPreference: WorkoutGoal.SplitPreference = .letAIDecide
    @State private var additionalNotes = ""

    // MARK: - Step 4: Review
    @State private var generatedPlan: WorkoutPlan?
    @State private var isGenerating = false
    @State private var generationError: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Step indicator
                if currentStep <= totalSteps {
                    stepIndicator
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                }

                // Content
                Group {
                    switch currentStep {
                    case 1: step1GoalExperience
                    case 2: step2MuscleGroupsEquipment
                    case 3: step3SchedulePreferences
                    case 4: step4ReviewPlan
                    default: EmptyView()
                    }
                }

                // Navigation buttons
                if currentStep <= totalSteps {
                    navigationButtons
                        .padding()
                }
            }
            .navigationTitle(currentStep <= totalSteps ? String(localized: "New Plan") : String(localized: "Review Plan"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(String(localized: "Cancel")) {
                        dismiss()
                    }
                }
            }
            .safeAreaInset(edge: .top) {
                if !subscriptionManager.isPremium && currentStep <= totalSteps {
                    planLimitBanner
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView(feature: .unlimitedPlans)
            }
        }
    }

    // MARK: - Plan Limit Banner

    private var planLimitBanner: some View {
        Group {
            if subscriptionManager.canGeneratePlan {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.blue)
                    Text(String(localized: "\(subscriptionManager.remainingFreePlans) free plan\(subscriptionManager.remainingFreePlans == 1 ? "" : "s") remaining this month"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.08))
            } else {
                HStack {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.orange)
                    Text(String(localized: "Free limit reached"))
                        .font(.caption.bold())
                    Spacer()
                    Button(String(localized: "Upgrade")) {
                        showingPaywall = true
                    }
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .clipShape(Capsule())
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
            }
        }
    }

    // MARK: - Step Indicator

    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(1...totalSteps, id: \.self) { step in
                Circle()
                    .fill(step == currentStep ? Color.blue : (step < currentStep ? Color.blue.opacity(0.5) : Color.secondary.opacity(0.3)))
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Step 1: Goal & Experience

    private var step1GoalExperience: some View {
        Form {
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "target")
                        .font(.system(size: 44))
                        .foregroundStyle(.blue)

                    Text(String(localized: "Goal & Experience"))
                        .font(.title2.bold())

                    Text(String(localized: "What are you training for and what's your experience level?"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
                .listRowBackground(Color.clear)
            }

            Section(String(localized: "What's your goal?")) {
                Picker(String(localized: "Goal"), selection: $goalType) {
                    ForEach(WorkoutGoal.GoalType.allCases, id: \.self) { goal in
                        Text(goal.displayName).tag(goal)
                    }
                }
                .pickerStyle(.menu)
            }

            Section(String(localized: "Experience Level")) {
                Picker(String(localized: "Experience"), selection: $experienceLevel) {
                    ForEach(WorkoutGoal.ExperienceLevel.allCases, id: \.self) { level in
                        Text(level.displayName).tag(level)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    // MARK: - Step 2: Muscle Groups & Equipment

    private var step2MuscleGroupsEquipment: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 44))
                        .foregroundStyle(.blue)

                    Text(String(localized: "Target & Equipment"))
                        .font(.title2.bold())

                    Text(String(localized: "Select muscle groups to focus on and equipment you have access to"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)

                // Muscle Groups
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(String(localized: "Muscle Groups"))
                            .font(.headline)
                        Spacer()
                        if selectedMuscleGroups.isEmpty {
                            Text(String(localized: "All (default)"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Button(String(localized: "Clear")) {
                                selectedMuscleGroups.removeAll()
                            }
                            .font(.caption)
                        }
                    }

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                        ForEach(MuscleGroup.allCases, id: \.self) { muscle in
                            toggleChip(
                                label: muscle.displayName,
                                icon: muscle.icon,
                                isSelected: selectedMuscleGroups.contains(muscle)
                            ) {
                                if selectedMuscleGroups.contains(muscle) {
                                    selectedMuscleGroups.remove(muscle)
                                } else {
                                    selectedMuscleGroups.insert(muscle)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)

                // Equipment
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(String(localized: "Available Equipment"))
                            .font(.headline)
                        Spacer()
                        if selectedEquipment.isEmpty {
                            Text(String(localized: "All (default)"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Button(String(localized: "Clear")) {
                                selectedEquipment.removeAll()
                            }
                            .font(.caption)
                        }
                    }

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 8)], spacing: 8) {
                        ForEach(ExerciseEquipment.allCases, id: \.self) { equipment in
                            toggleChip(
                                label: equipment.displayName,
                                icon: equipment.icon,
                                isSelected: selectedEquipment.contains(equipment)
                            ) {
                                if selectedEquipment.contains(equipment) {
                                    selectedEquipment.remove(equipment)
                                } else {
                                    selectedEquipment.insert(equipment)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 8)
        }
    }

    // MARK: - Step 3: Schedule & Preferences

    private var step3SchedulePreferences: some View {
        Form {
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 44))
                        .foregroundStyle(.blue)

                    Text(String(localized: "Schedule & Preferences"))
                        .font(.title2.bold())

                    Text(String(localized: "Set your training schedule and split preference"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
                .listRowBackground(Color.clear)
            }

            Section(String(localized: "Schedule")) {
                Stepper(String(localized: "Days per week: \(daysPerWeek)"), value: $daysPerWeek, in: 2...6)

                VStack(alignment: .leading) {
                    HStack {
                        Text(String(localized: "Session length"))
                        Spacer()
                        Text(String(localized: "\(sessionLength) min"))
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: Binding(
                        get: { Double(sessionLength) },
                        set: { sessionLength = Int($0) }
                    ), in: 30...120, step: 15)
                }
            }

            Section(String(localized: "Training Split")) {
                Picker(String(localized: "Split"), selection: $splitPreference) {
                    ForEach(WorkoutGoal.SplitPreference.allCases, id: \.self) { split in
                        Text(split.displayName).tag(split)
                    }
                }
                .pickerStyle(.menu)
            }

            Section(String(localized: "Additional Notes (Optional)")) {
                TextField(String(localized: "Injuries, focus areas, preferences..."), text: $additionalNotes, axis: .vertical)
                    .lineLimit(3...5)
            }
        }
    }

    // MARK: - Step 4: Review Generated Plan

    private var step4ReviewPlan: some View {
        Group {
            if isGenerating {
                VStack(spacing: 16) {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                    Text(String(localized: "Generating your plan..."))
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text(String(localized: "This may take a moment"))
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else if let error = generationError {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.orange)
                    Text(String(localized: "Generation Failed"))
                        .font(.title3.bold())
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    HStack(spacing: 16) {
                        Button(String(localized: "Back")) {
                            currentStep = totalSteps
                            generationError = nil
                        }
                        .buttonStyle(.bordered)

                        Button(String(localized: "Retry")) {
                            generatePlan()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else if let plan = generatedPlan {
                planReviewContent(plan)
            }
        }
    }

    private func planReviewContent(_ plan: WorkoutPlan) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Plan header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(plan.name)
                            .font(.title2.bold())
                        Text(plan.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.top)

                    // Workout days
                    ForEach(plan.days) { day in
                        workoutDayCard(day)
                    }

                    // Tips
                    if let tips = plan.tips, !tips.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(String(localized: "Tips"))
                                .font(.headline)
                            ForEach(tips, id: \.self) { tip in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundStyle(.yellow)
                                        .font(.caption)
                                        .padding(.top, 2)
                                    Text(tip)
                                        .font(.subheadline)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 16)
            }

            // Action buttons
            reviewActionButtons
        }
    }

    private func workoutDayCard(_ day: WorkoutDay) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(day.name)
                    .font(.headline)
                Spacer()
                Text(day.focus)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Capsule())
            }

            Divider()

            ForEach(day.exercises) { exercise in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.name)
                            .font(.subheadline.weight(.medium))
                        if let notes = exercise.notes, !notes.isEmpty {
                            Text(notes)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Text(String(localized: "\(exercise.sets)×\(exercise.reps)"))
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                        .monospacedDigit()
                }
                .padding(.vertical, 2)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    private var reviewActionButtons: some View {
        VStack(spacing: 8) {
            Divider()
            HStack(spacing: 12) {
                Button {
                    dismiss()
                } label: {
                    Text(String(localized: "Discard"))
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
                .tint(.red)

                Button {
                    generatePlan()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                        Text(String(localized: "Regenerate"))
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)

                Button {
                    if let plan = generatedPlan {
                        viewModel.acceptPlan(plan)
                        dismiss()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                        Text(String(localized: "Accept"))
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if currentStep > 1 {
                Button {
                    withAnimation {
                        currentStep -= 1
                    }
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text(String(localized: "Back"))
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
            }

            Button {
                if currentStep == totalSteps {
                    // Generate and go to review
                    withAnimation {
                        currentStep = 4
                    }
                    generatePlan()
                } else {
                    withAnimation {
                        currentStep += 1
                    }
                }
            } label: {
                HStack {
                    if currentStep == totalSteps {
                        Image(systemName: "sparkles")
                        Text(String(localized: "Generate Plan"))
                    } else {
                        Text(String(localized: "Next"))
                        Image(systemName: "chevron.right")
                    }
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Toggle Chip

    private func toggleChip(label: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(label)
                    .font(.caption)
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.blue.opacity(0.15) : Color(.tertiarySystemGroupedBackground))
            .foregroundStyle(isSelected ? .blue : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Generate Plan

    private func generatePlan() {
        isGenerating = true
        generationError = nil
        generatedPlan = nil

        let goal = WorkoutGoal(
            type: goalType,
            daysPerWeek: daysPerWeek,
            sessionLength: sessionLength,
            experienceLevel: experienceLevel,
            targetMuscleGroups: Array(selectedMuscleGroups),
            availableEquipment: Array(selectedEquipment),
            splitPreference: splitPreference,
            additionalNotes: additionalNotes
        )

        Task {
            do {
                let plan = try await viewModel.previewWorkoutPlan(goal: goal)
                generatedPlan = plan
            } catch {
                generationError = error.localizedDescription
            }
            isGenerating = false
        }
    }
}

#Preview {
    WorkoutPlanGeneratorView(viewModel: GymViewModel())
        .environmentObject(SubscriptionManager.shared)
}
